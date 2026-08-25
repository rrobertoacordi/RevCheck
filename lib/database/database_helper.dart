import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('revchek.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');

    // Tabela de Equipamentos (Maquinários)
    await db.execute('''
      CREATE TABLE equipamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        codigo TEXT UNIQUE NOT NULL,
        modelo TEXT,
        horometro_atual REAL DEFAULT 0
      )
    ''');

    // Tabela de Compartimentos
    await db.execute('''
      CREATE TABLE compartimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipamento_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        FOREIGN KEY (equipamento_id) REFERENCES equipamentos(id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Trocas de Filtro
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
  }

  Future<int> insertEquipamento(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('equipamentos', row);
  }

  Future<List<Map<String, dynamic>>> getEquipamentos() async {
    final db = await instance.database;
    return await db.query('equipamentos', orderBy: 'nome ASC');
  }

  Future<int> deleteEquipamento(int id) async {
    final db = await instance.database;
    return await db.delete('equipamentos', where: 'id = ?', whereArgs: [id]);
  }

  // --- COMPARTIMENTOS E FILTROS ---

  // Inserir Compartimento/Filtro
  Future<int> insertCompartimento(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('compartimentos', row);
  }

  // Buscar todos os compartimentos de um equipamento específico
  Future<List<Map<String, dynamic>>> getCompartimentosPorEquipamento(
    int equipamentoId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'compartimentos',
      where: 'equipamento_id = ?',
      whereArgs: [equipamentoId],
      orderBy: 'id DESC',
    );
  }

  // Inserir registro de troca/instalação de filtro
  Future<int> insertTrocaFiltro(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('trocas_filtro', row);
  }

  // Buscar última troca/instalação de um compartimento
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

  // Deletar um compartimento/filtro
  Future<int> deleteCompartimento(int id) async {
    final db = await instance.database;
    return await db.delete('compartimentos', where: 'id = ?', whereArgs: [id]);
  }
}
