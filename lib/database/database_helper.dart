import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/equipamento.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('revcheck.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Versão 3 (Lembretes por compartimento)
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS lembretes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              equipamento_id INTEGER NOT NULL,
              data_hora TEXT NOT NULL,
              observacao TEXT,
              FOREIGN KEY (equipamento_id) REFERENCES equipamentos(id) ON DELETE CASCADE
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE lembretes ADD COLUMN compartimento_id INTEGER
          ''');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabela de Equipamentos
    await db.execute('''
      CREATE TABLE equipamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL,
        nome TEXT NOT NULL,
        horometro_atual REAL NOT NULL,
        lembrete_data TEXT,
        lembrete_obs TEXT
      )
    ''');

    // 2. Tabela de Compartimentos
    await db.execute('''
      CREATE TABLE compartimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipamento_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        FOREIGN KEY (equipamento_id) REFERENCES equipamentos(id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabela de Trocas de Filtro
    await db.execute('''
      CREATE TABLE trocas_filtro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        compartimento_id INTEGER NOT NULL,
        codigo_filtro TEXT NOT NULL,
        descricao_filtro TEXT,
        horas_trocadas REAL NOT NULL,
        proxima_troca REAL,
        data_troca TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (compartimento_id) REFERENCES compartimentos(id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabela de Lembretes
    await db.execute('''
      CREATE TABLE lembretes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipamento_id INTEGER NOT NULL,
        compartimento_id INTEGER,
        data_hora TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (equipamento_id) REFERENCES equipamentos(id) ON DELETE CASCADE,
        FOREIGN KEY (compartimento_id) REFERENCES compartimentos(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- MÉTODOS DE EQUIPAMENTOS ---

  Future<int> insertEquipamento(Equipamento equipamento) async {
    final db = await instance.database;
    return await db.insert('equipamentos', equipamento.toMap());
  }

  Future<List<Map<String, dynamic>>> getEquipamentos() async {
    final db = await instance.database;
    return await db.query('equipamentos', orderBy: 'id DESC');
  }

  Future<int> deleteEquipamento(int id) async {
    final db = await instance.database;
    return await db.delete('equipamentos', where: 'id = ?', whereArgs: [id]);
  }

  // --- MÉTODOS DE COMPARTIMENTOS ---

  Future<int> insertCompartimento(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('compartimentos', row);
  }

  Future<List<Map<String, dynamic>>> getCompartimentosPorEquipamento(
    int equipamentoId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'compartimentos',
      where: 'equipamento_id = ?',
      whereArgs: [equipamentoId],
    );
  }

  Future<int> deleteCompartimento(int id) async {
    final db = await instance.database;
    return await db.delete('compartimentos', where: 'id = ?', whereArgs: [id]);
  }

  // --- MÉTODOS DE TROCAS DE FILTRO ---

  Future<int> insertTrocaFiltro(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('trocas_filtro', row);
  }

  Future<List<Map<String, dynamic>>> getTrocasPorCompartimento(
    int compartimentoId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'trocas_filtro',
      where: 'compartimento_id = ?',
      whereArgs: [compartimentoId],
      orderBy: 'id DESC',
    );
  }

  // --- MÉTODOS DE LEMBRETES ---

  Future<int> insertLembrete(
    int equipamentoId,
    String dataIso,
    String obs,
  ) async {
    final db = await instance.database;
    return await db.insert('lembretes', {
      'equipamento_id': equipamentoId,
      'data_hora': dataIso,
      'observacao': obs,
    });
  }

  Future<int> insertLembreteCompartimento({
    required int equipamentoId,
    required int compartimentoId,
    required String dataHora,
    required String observacao,
  }) async {
    final db = await instance.database;
    return await db.insert('lembretes', {
      'equipamento_id': equipamentoId,
      'compartimento_id': compartimentoId,
      'data_hora': dataHora,
      'observacao': observacao,
    });
  }

  Future<List<Map<String, dynamic>>> getLembretesPorEquipamento(
    int equipamentoId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'lembretes',
      where: 'equipamento_id = ?',
      whereArgs: [equipamentoId],
      orderBy: 'data_hora ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getLembretesPorCompartimento(
    int compartimentoId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'lembretes',
      where: 'compartimento_id = ?',
      whereArgs: [compartimentoId],
      orderBy: 'data_hora ASC',
    );
  }

  Future<int> deleteLembrete(int id) async {
    final db = await instance.database;
    return await db.delete('lembretes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // --- MÉTODOS DE BACKUP E RESTAURAÇÃO ---

  /// Converte todo o banco de dados para uma String JSON
  Future<String> exportarParaJson() async {
    final db = await instance.database;

    final equipamentos = await db.query('equipamentos');
    final compartimentos = await db.query('compartimentos');
    final trocas = await db.query('trocas_filtro');
    final lembretes = await db.query('lembretes');

    final backupMap = {
      'versao': 3,
      'data_backup': DateTime.now().toIso8601String(),
      'equipamentos': equipamentos,
      'compartimentos': compartimentos,
      'trocas_filtro': trocas,
      'lembretes': lembretes,
    };

    return jsonEncode(backupMap);
  }

  /// Limpa o banco atual e restaura os dados a partir de um JSON
  Future<void> importarDeJson(String jsonString) async {
    final db = await instance.database;
    final Map<String, dynamic> backupMap = jsonDecode(jsonString);

    await db.transaction((txn) async {
      // 1. Limpa todas as tabelas atuais na ordem das chaves estrangeiras
      await txn.delete('lembretes');
      await txn.delete('trocas_filtro');
      await txn.delete('compartimentos');
      await txn.delete('equipamentos');

      // 2. Restaura Equipamentos
      final List equipamentos = backupMap['equipamentos'] ?? [];
      for (var item in equipamentos) {
        await txn.insert('equipamentos', Map<String, dynamic>.from(item));
      }

      // 3. Restaura Compartimentos
      final List compartimentos = backupMap['compartimentos'] ?? [];
      for (var item in compartimentos) {
        await txn.insert('compartimentos', Map<String, dynamic>.from(item));
      }

      // 4. Restaura Trocas de Filtro
      final List trocas = backupMap['trocas_filtro'] ?? [];
      for (var item in trocas) {
        await txn.insert('trocas_filtro', Map<String, dynamic>.from(item));
      }

      // 5. Restaura Lembretes
      final List lembretes = backupMap['lembretes'] ?? [];
      for (var item in lembretes) {
        await txn.insert('lembretes', Map<String, dynamic>.from(item));
      }
    });
  }
}
