import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/categorie_produit_model.dart';
import 'package:project6/services/database_helper.dart';

final categorieProduitControllerProvider = AsyncNotifierProvider<CategorieProduitController, List<CategorieProduit>>(
  CategorieProduitController.new,
);

class CategorieProduitController extends AsyncNotifier<List<CategorieProduit>> {
  final _dbHelper = DatabaseHelper.instance;
  String? _currentEntrepriseId;

  @override
  Future<List<CategorieProduit>> build() async {
    // Retourner une liste vide au début
    return [];
  }

  Future<void> loadCategories(String entrepriseId) async {
    // Éviter de recharger si c'est la même entreprise
    if (_currentEntrepriseId == entrepriseId && state is! AsyncError) {
      return;
    }
    
    _currentEntrepriseId = entrepriseId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadCategories(entrepriseId: entrepriseId));
  }

  Future<List<CategorieProduit>> _loadCategories({required String entrepriseId}) async {
    final db = await _dbHelper.database;
    final categories = await db.query(
      'categorie_produit',
      where: 'entreprise_id = ?',
      whereArgs: [entrepriseId],
      orderBy: 'libelle ASC',
    );

    return categories.map(CategorieProduit.fromMap).toList();
  }

  Future<void> addCategorie(String libelle, String entrepriseId) async {
    try {
      final db = await _dbHelper.database;
      
      final newCategorie = {
        'libelle': libelle.trim(),
        'entreprise_id': entrepriseId,
        'created_at': DateTime.now().toIso8601String(),
      };

      await db.insert('categorie_produit', newCategorie);

      // Recharger seulement si c'est la même entreprise
      if (_currentEntrepriseId == entrepriseId) {
        state = await AsyncValue.guard(() => _loadCategories(entrepriseId: entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> updateCategorie(CategorieProduit categorie) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'categorie_produit',
        {
          'libelle': categorie.libelle.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND entreprise_id = ?',
        whereArgs: [categorie.id, categorie.entrepriseId],
      );

      // Recharger seulement si c'est la même entreprise
      if (_currentEntrepriseId == categorie.entrepriseId) {
        state = await AsyncValue.guard(() => _loadCategories(entrepriseId: categorie.entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> deleteCategorie(int id, String entrepriseId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'categorie_produit',
        where: 'id = ? AND entreprise_id = ?',
        whereArgs: [id, entrepriseId],
      );

      // Recharger seulement si c'est la même entreprise
      if (_currentEntrepriseId == entrepriseId) {
        state = await AsyncValue.guard(() => _loadCategories(entrepriseId: entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}