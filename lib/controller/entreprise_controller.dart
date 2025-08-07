import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project6/models/entreprise_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:uuid/uuid.dart';

final entrepriseControllerProvider = AsyncNotifierProvider<EntrepriseController, List<Entreprise>>(
  EntrepriseController.new,
);

final activeEntrepriseProvider = Provider<AsyncValue<Entreprise?>>((ref) {
  final entreprisesAsync = ref.watch(entrepriseControllerProvider);
  
  return entreprisesAsync.when(
    loading: () => const AsyncLoading<Entreprise?>(),
    error: (err, stack) => AsyncError<Entreprise?>(err, stack),
    data: (entreprises) {
      if (entreprises.isEmpty) return const AsyncData<Entreprise?>(null);
      
      final active = entreprises.firstWhere(
        (e) => e.isActive,
        orElse: () => entreprises.first,
      );
      return AsyncData<Entreprise?>(active);
    },
  );
});

class EntrepriseController extends AsyncNotifier<List<Entreprise>> {
  final _dbHelper = DatabaseHelper.instance;
  final _secureStorage = const FlutterSecureStorage();

  @override
  Future<List<Entreprise>> build() async {
    return _loadEntreprises();
  }

  Future<List<Entreprise>> _loadEntreprises() async {
    final userId = await _secureStorage.read(key: 'user_id');
    if (userId == null) return [];

    final db = await _dbHelper.database;
    final entreprises = await db.query(
      'entreprises',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return entreprises.map(Entreprise.fromMap).toList();
  }

  Future<void> createEntreprise({
    required String nom,
    required String motDePasse,
    String? adresse,
  }) async {
    try {
      state = const AsyncLoading();
      final userId = await _secureStorage.read(key: 'user_id');
      if (userId == null) throw Exception('Utilisateur non connecté');

      final db = await _dbHelper.database;
      
      await db.insert('entreprises', {
        'id': const Uuid().v4(),
        'nom': nom,
        'adresse': adresse,
        'user_id': userId,
        'mot_de_passe': motDePasse,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });

      state = await AsyncValue.guard(() => _loadEntreprises());
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> setActiveEntreprise(String entrepriseId) async {
    try {
      state = const AsyncLoading();
      final db = await _dbHelper.database;
      final userId = await _secureStorage.read(key: 'user_id');
      
      await db.update(
        'entreprises',
        {'is_active': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      await db.update(
        'entreprises',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [entrepriseId],
      );

      state = await AsyncValue.guard(() => _loadEntreprises());
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}