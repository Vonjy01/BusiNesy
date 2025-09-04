// controller/client_controller.dart
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

  @override
  Future<List<Client>> build() async {
    return await _loadClients();
  }

  Future<List<Client>> _loadClients({String? entrepriseId}) async {
    final db = await _dbHelper.database;
    final where = entrepriseId != null ? 'entreprise_id = ?' : null;
    final whereArgs = entrepriseId != null ? [entrepriseId] : null;
    
    final clients = await db.query(
      'clients',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'nom ASC',
    );

    return clients.map(Client.fromMap).toList();
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
      state = const AsyncValue.loading();
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
      state = await AsyncValue.guard(() => _loadClients(entrepriseId: entrepriseId));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      state = const AsyncValue.loading();
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

      state = await AsyncValue.guard(() => _loadClients(entrepriseId: client.entrepriseId));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteClient(String id, String entrepriseId) async {
    try {
      state = const AsyncValue.loading();
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

      state = await AsyncValue.guard(() => _loadClients(entrepriseId: entrepriseId));
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

// Extension pour Client
extension ClientCopyWith on Client {
  Client copyWith({
    String? nom,
    String? telephone,
    String? email,
    String? adresse,
    String? description,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      entrepriseId: entrepriseId,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}