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

  @override
  Future<List<Fournisseur>> build() async {
    return _loadFournisseurs();
  }

  Future<List<Fournisseur>> _loadFournisseurs({String? entrepriseId}) async {
    final db = await _dbHelper.database;
    final where = entrepriseId != null ? 'entreprise_id = ?' : null;
    final whereArgs = entrepriseId != null ? [entrepriseId] : null;
    
    final fournisseurs = await db.query(
      'fournisseurs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'nom ASC',
    );

    return fournisseurs.map(Fournisseur.fromMap).toList();
  }

  Future<void> addFournisseur({
    required String nom,
    required String entrepriseId,
    String? telephone,
    String? email,
    String? adresse,
  }) async {
    try {
      state = const AsyncLoading();
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
      state = await AsyncValue.guard(() => _loadFournisseurs(entrepriseId: entrepriseId));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> updateFournisseur(Fournisseur fournisseur) async {
    try {
      state = const AsyncLoading();
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

      state = await AsyncValue.guard(() => _loadFournisseurs(entrepriseId: fournisseur.entrepriseId));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> deleteFournisseur(String id, String entrepriseId) async {
    try {
      state = const AsyncLoading();
      final db = await _dbHelper.database;

      await db.delete(
        'fournisseurs',
        where: 'id = ?',
        whereArgs: [id],
      );

      state = await AsyncValue.guard(() => _loadFournisseurs(entrepriseId: entrepriseId));
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
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

// Extension pour faciliter la mise à jour
extension FournisseurCopyWith on Fournisseur {
  Fournisseur copyWith({
    String? nom,
    String? telephone,
    String? email,
    String? adresse,
    DateTime? updatedAt,
  }) {
    return Fournisseur(
      id: id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      entrepriseId: entrepriseId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}