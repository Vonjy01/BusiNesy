import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/fournisseur_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:uuid/uuid.dart';

final fournisseurControllerProvider = AsyncNotifierProvider<FournisseurController, List<Fournisseur>>(
  FournisseurController.new,
);
class FournisseurController extends AsyncNotifier<List<Fournisseur>> {
  final _dbHelper = DatabaseHelper.instance;
  final _uuid = Uuid();
  String? _currentEntrepriseId;

  @override
  Future<List<Fournisseur>> build() async {
    return [];
  }

  Future<void> loadFournisseurs(String entrepriseId, {bool forceReload = false}) async {
    // ⚡ Corrigé : on recharge si forceReload est demandé
    if (!forceReload && _currentEntrepriseId == entrepriseId && state is! AsyncError) {
      return;
    }

    _currentEntrepriseId = entrepriseId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadFournisseurs(entrepriseId: entrepriseId));
  }

  Future<List<Fournisseur>> _loadFournisseurs({required String entrepriseId}) async {
    final db = await _dbHelper.database;

    final fournisseurs = await db.query(
      'fournisseurs',
      where: 'entreprise_id = ?',
      whereArgs: [entrepriseId],
      orderBy: 'nom ASC',
    );

    return fournisseurs.map(Fournisseur.fromMap).toList();
  }

  // ⚡ Corrigé : recherche directe en base (nom, téléphone, email, adresse)
Timer? _searchTimer;

Future<void> searchFournisseursMulti(String entrepriseId, String query) async {
  // Annuler la recherche précédente
  _searchTimer?.cancel();
  
  // Démarrer un nouveau timer
  _searchTimer = Timer(const Duration(milliseconds: 300), () async {
    try {
      final db = await _dbHelper.database;

      final fournisseurs = await db.query(
        'fournisseurs',
        where:
            'entreprise_id = ? AND (LOWER(nom) LIKE ? OR telephone LIKE ? OR LOWER(email) LIKE ? OR LOWER(adresse) LIKE ?)',
        whereArgs: [
          entrepriseId,
          '%${query.toLowerCase()}%',
          '%$query%',
          '%${query.toLowerCase()}%',
          '%${query.toLowerCase()}%',
        ],
        orderBy: 'nom ASC',
      );

      state = AsyncData(fournisseurs.map(Fournisseur.fromMap).toList());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  });
}


  Future<void> addFournisseur({
    required String nom,
    required String entrepriseId,
    String? telephone,
    String? email,
    String? adresse,
  }) async {
    try {
      final db = await _dbHelper.database;

      final fournisseur = Fournisseur(
        id: _uuid.v4(),
        nom: nom.trim(),
        telephone: telephone?.trim(),
        email: email?.trim(),
        adresse: adresse?.trim(),
        entrepriseId: entrepriseId,
        createdAt: DateTime.now(),
      );

      await db.insert('fournisseurs', fournisseur.toMap());
      
      // Recharger seulement si c'est la même entreprise
      if (_currentEntrepriseId == entrepriseId) {
        state = await AsyncValue.guard(() => _loadFournisseurs(entrepriseId: entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> updateFournisseur(Fournisseur fournisseur) async {
    try {
      final db = await _dbHelper.database;

      final updatedFournisseur = fournisseur.copyWith(
        updatedAt: DateTime.now(),
      );

      await db.update(
        'fournisseurs',
        updatedFournisseur.toMap(),
        where: 'id = ?',
        whereArgs: [fournisseur.id],
      );

      // Recharger seulement si c'est la même entreprise
      if (_currentEntrepriseId == fournisseur.entrepriseId) {
        state = await AsyncValue.guard(() => _loadFournisseurs(entrepriseId: fournisseur.entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> deleteFournisseur(String id, String entrepriseId) async {
    try {
      final db = await _dbHelper.database;

      await db.delete(
        'fournisseurs',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Recharger seulement si c'est la même entreprise
      if (_currentEntrepriseId == entrepriseId) {
        state = await AsyncValue.guard(() => _loadFournisseurs(entrepriseId: entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
Future<void> searchFournisseurs(String entrepriseId, String query) async {
  final db = await _dbHelper.database;

  final fournisseurs = await db.query(
    'fournisseurs',
    where: 'entreprise_id = ? AND nom LIKE ?',
    whereArgs: [entrepriseId, '%$query%'],
    orderBy: 'nom ASC',
  );

  state = AsyncData(fournisseurs.map(Fournisseur.fromMap).toList());
}

  Future<Fournisseur?> getFournisseurById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'fournisseurs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isEmpty ? null : Fournisseur.fromMap(result.first);
  }
  
}