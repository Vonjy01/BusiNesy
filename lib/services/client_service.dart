import 'package:project6/models/client_model.dart';
import 'package:project6/services/database_helper.dart';

class ClientService {
  final DatabaseHelper _dbHelper;

  ClientService(this._dbHelper);

  Future<int> create(Client client) async {
    final db = await _dbHelper.database;
    return await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAll(String entrepriseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'clients',
      where: 'entreprise_id = ?',
      whereArgs: [entrepriseId],
      orderBy: 'nom ASC',
    );
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Client.fromMap(maps.first) : null;
  }

  Future<int> update(Client client) async {
    final db = await _dbHelper.database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}