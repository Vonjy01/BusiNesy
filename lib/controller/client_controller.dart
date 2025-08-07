import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/models/client_model.dart';
import 'package:project6/provider/client_provider.dart';
import 'package:project6/services/client_service.dart';

final clientServiceProvider = Provider<ClientService>((ref) {
  final dbHelper = ref.read(databaseHelperProvider);
  return ClientService(dbHelper);
});

final clientControllerProvider = StateNotifierProvider<ClientController, AsyncValue<List<Client>>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final entrepriseId = authState.value?.id ?? '';
  final service = ref.read(clientServiceProvider);
  return ClientController(service, entrepriseId);
});

class ClientController extends StateNotifier<AsyncValue<List<Client>>> {
  final ClientService _service;
  final String _entrepriseId;

  ClientController(this._service, this._entrepriseId) : super(const AsyncValue.loading()) {
    _loadClients();
  }

  Future<void> _loadClients() async {
    state = const AsyncValue.loading();
    try {
      final clients = await _service.getAll(_entrepriseId);
      state = AsyncValue.data(clients);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addClient(Client client) async {
    try {
      await _service.create(client);
      await _loadClients();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      await _service.update(client);
      await _loadClients();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteClient(int id) async {
    try {
      await _service.delete(id);
      await _loadClients();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}