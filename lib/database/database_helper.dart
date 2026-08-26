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
      version: 2, // Incrementado para recriar/atualizar a estrutura
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
        data_hora TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (equipamento_id) REFERENCES equipamentos(id) ON DELETE CASCADE
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

  Future<int> deleteLembrete(int id) async {
    final db = await instance.database;
    return await db.delete('lembretes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
