// vente_controller.dart
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
        
        // GESTION DES ÉTATS POUR LES VENTES
        if (vente.etat == 2 || vente.etat == 3) { // Validé ou Incomplet
          await _updateStockForVente(txn, vente, userId, isAdding: true);
        }
        // État 1 (En attente) et 4 (Annulé) ne modifient pas le stock à l'ajout
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
          await txn.insert('ventes', vente.toMap());
          
          // GESTION DES ÉTATS POUR LES VENTES
          if (vente.etat == 2 || vente.etat == 3) { // Validé ou Incomplet
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
        
        // GESTION DES TRANSITIONS D'ÉTAT POUR LES VENTES
        await _handleStateChanges(txn, ancienneVente, vente, userId);
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
Future<void> _handleStateChanges(Transaction txn, Vente ancienneVente, Vente nouvelleVente, String userId) async {
  final ancienneQuantiteNet = ancienneVente.quantite - ancienneVente.produitRevenu;
  final nouvelleQuantiteNet = nouvelleVente.quantite - nouvelleVente.produitRevenu;

  // CAS 1: Ancien état était Validé (2) ou Incomplet (3) et nouveau état est Annulé (4)
  if ((ancienneVente.etat == 2 || ancienneVente.etat == 3) && nouvelleVente.etat == 4) {
    // Annuler l'effet sur le stock (remettre la quantité) - isAdding: false pour AUGMENTER le stock
    await _updateStockForVente(txn, ancienneVente, userId, isAdding: false);
  }

  // CAS 2: Ancien état était Annulé (4) ou En attente (1) et nouveau état est Validé (2) ou Incomplet (3)
  else if ((ancienneVente.etat == 4 || ancienneVente.etat == 1) && 
           (nouvelleVente.etat == 2 || nouvelleVente.etat == 3)) {
    // Appliquer l'effet sur le stock (enlever la quantité) - isAdding: true pour DIMINUER le stock
    await _updateStockForVente(txn, nouvelleVente, userId, isAdding: true);
  }

  // CAS 3: Ancien état était Validé (2) ou Incomplet (3) et nouveau état est En attente (1)
  else if ((ancienneVente.etat == 2 || ancienneVente.etat == 3) && nouvelleVente.etat == 1) {
    // Annuler l'effet sur le stock (remettre la quantité) - isAdding: false pour AUGMENTER le stock
    await _updateStockForVente(txn, ancienneVente, userId, isAdding: false);
  }

  // CAS 4: Même état (Validé/Incomplet) mais quantité modifiée
  else if ((ancienneVente.etat == 2 || ancienneVente.etat == 3) && 
           (nouvelleVente.etat == 2 || nouvelleVente.etat == 3) &&
           (ancienneQuantiteNet != nouvelleQuantiteNet)) {
    
    // Annuler l'ancien effet (remettre l'ancienne quantité) - isAdding: false pour AUGMENTER
    await _updateStockForVente(txn, ancienneVente, userId, isAdding: false);
    
    // Appliquer le nouvel effet (enlever la nouvelle quantité) - isAdding: true pour DIMINUER
    await _updateStockForVente(txn, nouvelleVente, userId, isAdding: true);
  }

  // CAS 5: Changement d'état entre Validé et Incomplet (même traitement stock)
  else if ((ancienneVente.etat == 2 && nouvelleVente.etat == 3) || 
           (ancienneVente.etat == 3 && nouvelleVente.etat == 2)) {
    // Aucun changement de stock nécessaire car la quantité nette est la même
    print('Changement d\'état sans modification de stock: ${ancienneVente.etat} -> ${nouvelleVente.etat}');
  }

  // CAS 6: Changement de produitRevenu avec même état Validé/Incomplet
  else if ((ancienneVente.etat == 2 || ancienneVente.etat == 3) && 
           (nouvelleVente.etat == 2 || nouvelleVente.etat == 3) &&
           (ancienneVente.produitRevenu != nouvelleVente.produitRevenu)) {
    
    // Recalculer l'ajustement nécessaire
    final ajustement = (nouvelleVente.produitRevenu - ancienneVente.produitRevenu);
    
    if (ajustement != 0) {
      // L'ajustement est positif si produitRevenu augmente (donc on doit augmenter le stock)
      // L'ajustement est négatif si produitRevenu diminue (donc on doit diminuer le stock)
      await _adjustStockForRevenuChange(txn, nouvelleVente, userId, ajustement);
    }
  }
}

// Nouvelle méthode pour gérer les changements de produitRevenu
Future<void> _adjustStockForRevenuChange(Transaction txn, Vente vente, String userId, int ajustement) async {
  final produitResult = await txn.query(
    'produits',
    where: 'id = ?',
    whereArgs: [vente.produitId],
  );

  if (produitResult.isNotEmpty) {
    final produit = Produit.fromMap(produitResult.first);
    final nouveauStock = produit.stock + ajustement;
    
    if (nouveauStock < 0) {
      throw Exception('Stock insuffisant pour ${produit.nom} après ajustement');
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

    final description = ajustement > 0 
        ? 'Ajustement vente (Revenu +$ajustement) - ${produit.nom}'
        : 'Ajustement vente (Revenu $ajustement) - ${produit.nom}';

    await txn.insert('historique_stocks', {
      'produit_id': vente.produitId,
      'quantite': ajustement,
      'defectueux': 0,
      'description': description,
      'type': 2,
      'user_id': userId,
      'entreprise_id': vente.entrepriseId,
      'created_at': DateTime.now().toIso8601String(),
    });

    print('Ajustement revenu: ${produit.nom} - Adjustment: $ajustement, Nouveau stock: $nouveauStock');
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
          
          // Si la vente était validée ou incomplète, remettre le stock
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
            // Si la vente était validée ou incomplète, remettre le stock
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