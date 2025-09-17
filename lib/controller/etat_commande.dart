// controller/etat_commande_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/etat_commande.dart';
import 'package:project6/services/database_helper.dart';

final etatCommandeControllerProvider = AsyncNotifierProvider<EtatCommandeController, List<EtatCommande>>(
  EtatCommandeController.new,
);

class EtatCommandeController extends AsyncNotifier<List<EtatCommande>> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<EtatCommande>> build() async {
    return await _loadEtatsCommande();
  }

  Future<List<EtatCommande>> _loadEtatsCommande() async {
    try {
      final db = await _dbHelper.database;
      final etats = await db.query(
        'etat_commande',
        orderBy: 'id ASC',
      );
      return etats.map(EtatCommande.fromMap).toList();
    } catch (e, stack) {
      print('Error loading etats commande: $e\n$stack');
      rethrow;
    }
  }

  Future<EtatCommande?> getEtatById(int id) async {
    final etats = state.value;
    if (etats != null) {
      return etats.firstWhere(
        (etat) => etat.id == id,
        orElse: () => EtatCommande(
          id: 0,
          libelle: 'Inconnu',
        ),
      );
    }
    return null;
  }

  Future<void> refreshEtats() async {
    state = await AsyncValue.guard(() => _loadEtatsCommande());
  }
}