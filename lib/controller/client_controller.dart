import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/client_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:uuid/uuid.dart';

final clientControllerProvider = AsyncNotifierProvider<ClientController, List<Client>>(
  ClientController.new,
);

class ClientController extends AsyncNotifier<List<Client>> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();
  String? _currentEntrepriseId;

  @override
  Future<List<Client>> build() async {
    return [];
  }

  Future<void> loadClients(String entrepriseId, {bool forceReload = false}) async {
    if (!forceReload && _currentEntrepriseId == entrepriseId && state is! AsyncError) {
      return;
    }
    
    _currentEntrepriseId = entrepriseId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadClients(entrepriseId: entrepriseId));
  }

  Future<List<Client>> _loadClients({required String entrepriseId}) async {
    final db = await _dbHelper.database;
    
    final clients = await db.query(
      'clients',
      where: 'entreprise_id = ?',
      whereArgs: [entrepriseId],
      orderBy: 'nom ASC',
    );

    return clients.map(Client.fromMap).toList();
  }

  // ⚡ NOUVELLE MÉTHODE : Recherche multi-critères
  Future<void> searchClientsMulti(String entrepriseId, String query) async {
    final db = await _dbHelper.database;

    final clients = await db.query(
      'clients',
      where:
          'entreprise_id = ? AND (LOWER(nom) LIKE ? OR telephone LIKE ? OR LOWER(email) LIKE ? OR LOWER(adresse) LIKE ? OR LOWER(description) LIKE ?)',
      whereArgs: [
        entrepriseId,
        '%${query.toLowerCase()}%',
        '%$query%',
        '%${query.toLowerCase()}%',
        '%${query.toLowerCase()}%',
        '%${query.toLowerCase()}%',
      ],
      orderBy: 'nom ASC',
    );

    state = AsyncData(clients.map(Client.fromMap).toList());
  }

  Future<void> addClient({
    required String nom,
    required String entrepriseId,
    String? telephone,
    String? email,
    String? adresse,
    String? description,
  }) async {
    try {
      final db = await _dbHelper.database;

      final client = Client(
        id: _uuid.v4(),
        nom: nom.trim(),
        telephone: telephone?.trim(),
        email: email?.trim(),
        adresse: adresse?.trim(),
        entrepriseId: entrepriseId,
        description: description?.trim(),
        createdAt: DateTime.now(),
      );

      await db.insert('clients', client.toMap());
      
      if (_currentEntrepriseId == entrepriseId) {
        state = await AsyncValue.guard(() => _loadClients(entrepriseId: entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      final db = await _dbHelper.database;

      final updatedClient = client.copyWith(
        updatedAt: DateTime.now(),
      );

      await db.update(
        'clients',
        updatedClient.toMap(),
        where: 'id = ?',
        whereArgs: [client.id],
      );

      if (_currentEntrepriseId == client.entrepriseId) {
        state = await AsyncValue.guard(() => _loadClients(entrepriseId: client.entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteClient(String id, String entrepriseId) async {
    try {
      final db = await _dbHelper.database;

      await db.update(
        'ventes',
        {'client_id': null},
        where: 'client_id = ?',
        whereArgs: [id],
      );

      await db.delete(
        'clients',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (_currentEntrepriseId == entrepriseId) {
        state = await AsyncValue.guard(() => _loadClients(entrepriseId: entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<Client?> getClientById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isEmpty ? null : Client.fromMap(result.first);
  }
}