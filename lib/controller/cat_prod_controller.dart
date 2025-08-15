// lib/controller/categorie_produit_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/categorie_produit_model.dart';
import 'package:project6/services/database_helper.dart';

final categorieProduitControllerProvider = AsyncNotifierProvider<CategorieProduitController, List<CategorieProduit>>(
  CategorieProduitController.new,
);

class CategorieProduitController extends AsyncNotifier<List<CategorieProduit>> {
  final _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<CategorieProduit>> build() async {
    return _loadCategories();
  }

  Future<List<CategorieProduit>> _loadCategories() async {
    final activeEntreprise = ref.read(activeEntrepriseProvider).value;
    if (activeEntreprise == null) return [];

    final db = await _dbHelper.database;
    final categories = await db.query(
      'categorie_produit',
      where: 'entreprise_id = ?',
      whereArgs: [activeEntreprise.id],
      orderBy: 'libelle ASC',
    );

    return categories.map(CategorieProduit.fromMap).toList();
  }

  Future<void> addCategorie(String libelle) async {
    try {
      state = const AsyncLoading();
      final activeEntreprise = ref.read(activeEntrepriseProvider).value;
      if (activeEntreprise == null) throw Exception('Aucune entreprise sélectionnée');

      final db = await _dbHelper.database;
      await db.insert('categorie_produit', {
        'libelle': libelle.trim(),
        'entreprise_id': activeEntreprise.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      state = await AsyncValue.guard(() => _loadCategories());
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> updateCategorie(CategorieProduit categorie) async {
    try {
      state = const AsyncLoading();
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

      state = await AsyncValue.guard(() => _loadCategories());
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> deleteCategorie(int id, String entrepriseId) async {
    try {
      state = const AsyncLoading();
      final db = await _dbHelper.database;
      await db.delete(
        'categorie_produit',
        where: 'id = ? AND entreprise_id = ?',
        whereArgs: [id, entrepriseId],
      );

      state = await AsyncValue.guard(() => _loadCategories());
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}