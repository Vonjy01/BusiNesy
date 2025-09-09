import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/vente_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:uuid/uuid.dart';

final venteControllerProvider = AsyncNotifierProvider<VenteController, List<Vente>>(
  VenteController.new,
);

class VenteController extends AsyncNotifier<List<Vente>> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Vente>> build() async {
    return await _loadVentes();
  }

  Future<List<Vente>> _loadVentes() async {
    try {
      final db = await _dbHelper.database;
      final ventes = await db.query('ventes', orderBy: 'date_vente DESC');
      return ventes.map((map) => Vente.fromMap(map)).toList();
    } catch (e) {
      print('Error loading ventes: $e');
      return [];
    }
  }

  Future<void> addVente(Vente vente, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      await db.insert('ventes', vente.toMap());
      state = await AsyncValue.guard(_loadVentes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteVente(String id, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      await db.delete(
        'ventes',
        where: 'id = ?',
        whereArgs: [id],
      );

      state = await AsyncValue.guard(_loadVentes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> addVentes(List<Vente> ventes, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        for (final vente in ventes) {
          await txn.insert('ventes', vente.toMap());
        }
      });

      state = await AsyncValue.guard(_loadVentes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
