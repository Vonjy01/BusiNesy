import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/models/command_model.dart';
import 'package:project6/provider/client_provider.dart';
import 'package:project6/services/command_service.dart';

final commandeServiceProvider = Provider<CommandeService>((ref) {
  final dbHelper = ref.read(databaseHelperProvider);
  return CommandeService(dbHelper);
});

final commandeControllerProvider = AsyncNotifierProvider<CommandeController, List<Commande>>(
  CommandeController.new,
);

class CommandeController extends AsyncNotifier<List<Commande>> {
  CommandeService get _service => ref.read(commandeServiceProvider);

  @override
  Future<List<Commande>> build() async {
    final authState = ref.watch(authControllerProvider);
    final entrepriseId = authState.value?.id ?? '';
    if (entrepriseId.isEmpty) return [];
    return _service.getAll(entrepriseId);
  }

  Future<void> createCommande(Commande commande) async {
    state = const AsyncValue.loading();
    try {
      await _service.create(commande);
      await _refreshList(commande.entrepriseId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> validerReception({
    required String commandeId,
    required int quantiteRecue,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.validerReception(
        commandeId: commandeId,
        quantiteRecue: quantiteRecue,
        userId: userId,
      );
      final commande = await _service.getById(commandeId);
      if (commande != null) {
        await _refreshList(commande.entrepriseId);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> _refreshList(String entrepriseId) async {
    state = await AsyncValue.guard(() => _service.getAll(entrepriseId));
  }

  Future<List<EtatCommande>> getEtatsCommande() async {
    return _service.getEtatsCommande();
  }
}