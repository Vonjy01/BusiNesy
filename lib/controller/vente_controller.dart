import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/models/vente_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

final venteControllerProvider = AsyncNotifierProvider<VenteController, List<Vente>>(
  VenteController.new,
);

class VenteController extends AsyncNotifier<List<Vente>> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();
  String? _currentEntrepriseId;

  @override
  Future<List<Vente>> build() async {
    return [];
  }
    String generateNewSessionId() {
    return _uuid.v4();
  }

  Future<void> loadVentes(String entrepriseId) async {
    if (_currentEntrepriseId == entrepriseId && state is! AsyncError) {
      return;
    }
    
    _currentEntrepriseId = entrepriseId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadVentes(entrepriseId: entrepriseId));
  }

  Future<List<Vente>> _loadVentes({required String entrepriseId}) async {
    try {
      final db = await _dbHelper.database;
      final ventes = await db.query(
        'ventes',
        where: 'entreprise_id = ?',
        whereArgs: [entrepriseId],
        orderBy: 'date_vente DESC, session_id DESC'
      );
      return ventes.map(Vente.fromMap).toList();
    } catch (e, stack) {
      print('Error loading ventes: $e\n$stack');
      rethrow;
    }
  }

  Future<void> addVente(Vente vente, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        await txn.insert('ventes', vente.toMap());
        if (vente.etat == 2 || vente.etat == 3) {
          await _updateStockForVente(txn, vente, userId, isAdding: true);
        }
      });

      if (_currentEntrepriseId == vente.entrepriseId) {
        state = await AsyncValue.guard(() => _loadVentes(entrepriseId: vente.entrepriseId));
      }
    } catch (e, stack) {
      print('Error adding vente: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
Future<void> addVentesBatch(List<Vente> ventes, String userId) async {
  try {
    state = const AsyncValue.loading();
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      for (final vente in ventes) {
        // DEBUG: Affichez chaque vente avant insertion
        print('Insertion vente - Session: ${vente.sessionId}, Produit: ${vente.produitId}');
        
        await txn.insert('ventes', vente.toMap());
        if (vente.etat == 2 || vente.etat == 3) {
          await _updateStockForVente(txn, vente, userId, isAdding: true);
        }
      }
    });

    if (_currentEntrepriseId == ventes.first.entrepriseId) {
      state = await AsyncValue.guard(() => _loadVentes(entrepriseId: ventes.first.entrepriseId));
    }
  } catch (e, stack) {
    print('Error adding batch ventes: $e\n$stack');
    state = AsyncValue.error(e, stack);
    rethrow;
  }
}

  Future<void> updateVente(Vente vente, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      final ancienneVenteResult = await db.query(
        'ventes',
        where: 'id = ?',
        whereArgs: [vente.id],
      );
      
      if (ancienneVenteResult.isEmpty) {
        throw Exception('Vente non trouvée');
      }
      
      final ancienneVente = Vente.fromMap(ancienneVenteResult.first);

      await db.transaction((txn) async {
        await txn.update(
          'ventes',
          vente.toMap(),
          where: 'id = ?',
          whereArgs: [vente.id],
        );
        await _handleStateAndQuantityChanges(txn, ancienneVente, vente, userId);
      });

      if (_currentEntrepriseId == vente.entrepriseId) {
        state = await AsyncValue.guard(() => _loadVentes(entrepriseId: vente.entrepriseId));
      }
    } catch (e, stack) {
      print('Error updating vente: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteVente(String id, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      final venteResult = await db.query(
        'ventes',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (venteResult.isNotEmpty) {
        final vente = Vente.fromMap(venteResult.first);

        await db.transaction((txn) async {
          await txn.delete('ventes', where: 'id = ?', whereArgs: [id]);
          if (vente.etat == 2 || vente.etat == 3) {
            await _updateStockForVente(txn, vente, userId, isAdding: false);
          }
        });

        if (_currentEntrepriseId == vente.entrepriseId) {
          state = await AsyncValue.guard(() => _loadVentes(entrepriseId: vente.entrepriseId));
        }
      }
    } catch (e, stack) {
      print('Error deleting vente: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteVentesBySession(String sessionId, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      final ventesResult = await db.query(
        'ventes',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );

      if (ventesResult.isNotEmpty) {
        final ventes = ventesResult.map(Vente.fromMap).toList();

        await db.transaction((txn) async {
          await txn.delete('ventes', where: 'session_id = ?', whereArgs: [sessionId]);
          for (final vente in ventes) {
            if (vente.etat == 2 || vente.etat == 3) {
              await _updateStockForVente(txn, vente, userId, isAdding: false);
            }
          }
        });

        if (_currentEntrepriseId == ventes.first.entrepriseId) {
          state = await AsyncValue.guard(() => _loadVentes(entrepriseId: ventes.first.entrepriseId));
        }
      }
    } catch (e, stack) {
      print('Error deleting ventes by session: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> _updateStockForVente(Transaction txn, Vente vente, String userId, {required bool isAdding}) async {
    final produitResult = await txn.query(
      'produits',
      where: 'id = ?',
      whereArgs: [vente.produitId],
    );

    if (produitResult.isNotEmpty) {
      final produit = Produit.fromMap(produitResult.first);
      final quantiteNetVendue = vente.quantite - vente.produitRevenu;
      final quantiteAjustee = isAdding ? -quantiteNetVendue : quantiteNetVendue;
      final nouveauStock = produit.stock + quantiteAjustee;
      
      if (nouveauStock < 0) {
        throw Exception('Stock insuffisant pour ${produit.nom}');
      }

      await txn.update(
        'produits',
        {
          'stock': nouveauStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [vente.produitId],
      );

      await txn.insert('historique_stocks', {
        'produit_id': vente.produitId,
        'quantite': quantiteAjustee,
        'defectueux': 0,
        'description': isAdding ? 'Vente - ${produit.nom}' : 'Annulation vente - ${produit.nom}',
        'type': 2,
        'user_id': userId,
        'entreprise_id': vente.entrepriseId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _handleStateAndQuantityChanges(Transaction txn, Vente ancienneVente, Vente nouvelleVente, String userId) async {
    if (ancienneVente.etat != nouvelleVente.etat) {
      await _handleEtatChange(txn, ancienneVente, nouvelleVente.etat, userId);
    }

    if ((ancienneVente.quantite != nouvelleVente.quantite || 
         ancienneVente.produitRevenu != nouvelleVente.produitRevenu) &&
        (nouvelleVente.etat == 2 || nouvelleVente.etat == 3)) {
      
      await _updateStockForVente(txn, ancienneVente, userId, isAdding: false);
      await _updateStockForVente(txn, nouvelleVente, userId, isAdding: true);
    }
  }

  Future<void> _handleEtatChange(Transaction txn, Vente vente, int newEtat, String userId) async {
    final quantiteNetVendue = vente.quantite - vente.produitRevenu;

    if ((vente.etat == 2 || vente.etat == 3) && newEtat == 4) {
      await _updateStockForVente(txn, vente, userId, isAdding: false);
    }
    else if (vente.etat == 4 && (newEtat == 2 || newEtat == 3)) {
      await _updateStockForVente(txn, vente, userId, isAdding: true);
    }
    else if (vente.etat == 1 && (newEtat == 2 || newEtat == 3)) {
      await _updateStockForVente(txn, vente, userId, isAdding: true);
    }
    else if ((vente.etat == 2 || vente.etat == 3) && newEtat == 1) {
      await _updateStockForVente(txn, vente, userId, isAdding: false);
    }
  }

Map<String, List<Vente>> groupVentesBySession(List<Vente> ventes) {
  final Map<String, List<Vente>> grouped = {};
  
  for (final vente in ventes) {
    if (!grouped.containsKey(vente.sessionId)) {
      grouped[vente.sessionId] = [];
    }
    grouped[vente.sessionId]!.add(vente);
  }
  
  return grouped;
}

  Future<List<Vente>> getVentesBySession(String sessionId) async {
    try {
      final db = await _dbHelper.database;
      final ventes = await db.query(
        'ventes',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'created_at ASC'
      );
      return ventes.map(Vente.fromMap).toList();
    } catch (e, stack) {
      print('Error getting ventes by session: $e\n$stack');
      rethrow;
    }
  }
}