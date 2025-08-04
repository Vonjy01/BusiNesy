import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project6/models/entreprise_model.dart';
import 'package:project6/services/database_helper.dart';

final entrepriseControllerProvider =
    StateNotifierProvider<EntrepriseController, AsyncValue<List<Entreprise>>>((ref) {
  return EntrepriseController();
});

class EntrepriseController extends StateNotifier<AsyncValue<List<Entreprise>>> {
  EntrepriseController() : super(const AsyncValue.loading()) {
    _loadEntreprises();
  }

  Future<void> _loadEntreprises() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final data = await db.query('entreprises');
      final entreprises = data.map((e) => Entreprise.fromJson(e)).toList();
      state = AsyncValue.data(entreprises);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createEntreprise({
    required String nom,
    String? adresse,
    required String userId,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final entreprise = Entreprise(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: nom,
        adresse: adresse,
        userId: userId,
      );
      await db.insert('entreprises', entreprise.toJson());

      // Recharge la liste à jour
      final data = await db.query('entreprises');
      final entreprises = data.map((e) => Entreprise.fromJson(e)).toList();
      state = AsyncValue.data(entreprises);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
