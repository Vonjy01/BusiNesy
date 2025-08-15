import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:uuid/uuid.dart';

final produitControllerProvider = AsyncNotifierProvider<ProduitController, List<Produit>>(
  ProduitController.new,
);

class ProduitController extends AsyncNotifier<List<Produit>> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Produit>> build() async {
    return await loadProduits();
  }

  Future<List<Produit>> loadProduits() async {
    try {
      final db = await _dbHelper.database;
      final produits = await db.query('produits');
      return produits.map(Produit.fromMap).toList();
    } catch (e, stack) {
      print('Error loading produits: $e\n$stack');
      rethrow;
    }
  }

  Future<void> addProduit(Produit produit, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        await txn.insert('produits', produit.toMap());
        await txn.insert('historique_stocks', {
          'produit_id': produit.id,
          'quantite': produit.stock,
          'defectueux': produit.defectueux,
          'user_id': userId,
          'entreprise_id': produit.entrepriseId,
          'created_at': DateTime.now().toIso8601String(),
        });
      });

      state = await AsyncValue.guard(loadProduits);
    } catch (e, stack) {
      print('Error adding produit: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateProduit(Produit produit, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;
      final ancienProduit = state.value?.firstWhere((p) => p.id == produit.id);

      await db.transaction((txn) async {
        await txn.update(
          'produits',
          produit.toMap(),
          where: 'id = ?',
          whereArgs: [produit.id],
        );

        if (ancienProduit != null && 
            (ancienProduit.stock != produit.stock || 
             ancienProduit.defectueux != produit.defectueux)) {
          await txn.insert('historique_stocks', {
            'produit_id': produit.id,
            'quantite': produit.stock - ancienProduit.stock,
            'defectueux': produit.defectueux - ancienProduit.defectueux,
            'user_id': userId,
            'entreprise_id': produit.entrepriseId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      });

      state = await AsyncValue.guard(loadProduits);
    } catch (e, stack) {
      print('Error updating produit: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}