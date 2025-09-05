import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/vente_model.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

final venteControllerProvider = AsyncNotifierProvider<VenteController, List<Vente>>(
  VenteController.new,
);

class VenteController extends AsyncNotifier<List<Vente>> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Vente>> build() async {
    return await loadVentes();
  }

  Future<List<Vente>> loadVentes() async {
    try {
      final db = await _dbHelper.database;
      final ventes = await db.query('ventes', orderBy: 'date_vente DESC');
      return ventes.map(Vente.fromMap).toList();
    } catch (e, stack) {
      print('Error loading ventes: $e\n$stack');
      rethrow;
    }
  }

  
  // Dans VenteController
Future<Map<String, List<Vente>>> getVentesGroupedByClient() async {
  final ventes = await loadVentes();
  final Map<String, List<Vente>> grouped = {};
  
  for (final vente in ventes) {
    if (vente.clientId != null) {
      if (!grouped.containsKey(vente.clientId)) {
        grouped[vente.clientId!] = [];
      }
      grouped[vente.clientId!]!.add(vente);
    }
  }
  
  return grouped;
}

  Future<void> addVente(Vente vente, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        // Insérer la vente
        await txn.insert('ventes', vente.toMap());

        // Mettre à jour le stock seulement si la vente est validée (état 2) ou incomplète (état 3)
        if (vente.etat == 2 || vente.etat == 3) {
          await _updateStockForVente(txn, vente, userId, isAdding: true);
        }
      });

      state = await AsyncValue.guard(loadVentes);
    } catch (e, stack) {
      print('Error adding vente: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateVente(Vente vente, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      // Récupérer l'ancienne vente
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
        // Mettre à jour la vente
        await txn.update(
          'ventes',
          vente.toMap(),
          where: 'id = ?',
          whereArgs: [vente.id],
        );

        // Gestion des changements d'état et de quantité
        await _handleStateAndQuantityChanges(txn, ancienneVente, vente, userId);
      });

      state = await AsyncValue.guard(loadVentes);
    } catch (e, stack) {
      print('Error updating vente: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }// Ajoutez cette méthode à votre VenteController
Future<Map<String, List<Vente>>> getVentesGrouped() async {
  final ventes = await loadVentes();
  return groupVentesByClientAndDate(ventes);
}

  Future<void> updateVenteEtat(String venteId, int newEtat, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      // Récupérer la vente actuelle
      final venteResult = await db.query(
        'ventes',
        where: 'id = ?',
        whereArgs: [venteId],
      );
      
      if (venteResult.isEmpty) {
        throw Exception('Vente non trouvée');
      }
      
      final vente = Vente.fromMap(venteResult.first);

      await db.transaction((txn) async {
        // Mettre à jour l'état
        await txn.update(
          'ventes',
          {
            'etat': newEtat,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [venteId],
        );

        // Gestion du changement d'état
        if (vente.etat != newEtat) {
          await _handleEtatChange(txn, vente, newEtat, userId);
        }
      });

      state = await AsyncValue.guard(loadVentes);
    } catch (e, stack) {
      print('Error updating vente etat: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteVente(String id, String userId) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      // Récupérer la vente avant suppression
      final venteResult = await db.query(
        'ventes',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (venteResult.isNotEmpty) {
        final vente = Vente.fromMap(venteResult.first);

        await db.transaction((txn) async {
          // Supprimer la vente
          await txn.delete(
            'ventes',
            where: 'id = ?',
            whereArgs: [id],
          );

          // Restaurer le stock seulement si la vente était validée (état 2) ou incomplète (état 3)
          if (vente.etat == 2 || vente.etat == 3) {
            await _updateStockForVente(txn, vente, userId, isAdding: false);
          }
        });
      }

      state = await AsyncValue.guard(loadVentes);
    } catch (e, stack) {
      print('Error deleting vente: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // Méthodes helper pour la gestion du stock
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

      // Ajouter à l'historique des stocks
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
    // Si l'état change
    if (ancienneVente.etat != nouvelleVente.etat) {
      await _handleEtatChange(txn, ancienneVente, nouvelleVente.etat, userId);
    }

    // Si la quantité ou le produit_revenu change et que la vente est active (état 2 ou 3)
    if ((ancienneVente.quantite != nouvelleVente.quantite || 
         ancienneVente.produitRevenu != nouvelleVente.produitRevenu) &&
        (nouvelleVente.etat == 2 || nouvelleVente.etat == 3)) {
      
      // Restaurer l'ancienne quantité
      await _updateStockForVente(txn, ancienneVente, userId, isAdding: false);
      
      // Appliquer la nouvelle quantité
      await _updateStockForVente(txn, nouvelleVente, userId, isAdding: true);
    }
  }

  Future<void> _handleEtatChange(Transaction txn, Vente vente, int newEtat, String userId) async {
    final quantiteNetVendue = vente.quantite - vente.produitRevenu;

    // De Validé/Incomplet (2/3) à Annulé (4) - Restaurer le stock
    if ((vente.etat == 2 || vente.etat == 3) && newEtat == 4) {
      await _updateStockForVente(txn, vente, userId, isAdding: false);
    }
    
    // De Annulé (4) à Validé/Incomplet (2/3) - Déduire le stock
    else if (vente.etat == 4 && (newEtat == 2 || newEtat == 3)) {
      await _updateStockForVente(txn, vente, userId, isAdding: true);
    }
    
    // De En attente (1) à Validé/Incomplet (2/3) - Déduire le stock
    else if (vente.etat == 1 && (newEtat == 2 || newEtat == 3)) {
      await _updateStockForVente(txn, vente, userId, isAdding: true);
    }
    
    // De Validé/Incomplet (2/3) à En attente (1) - Restaurer le stock
    else if ((vente.etat == 2 || vente.etat == 3) && newEtat == 1) {
      await _updateStockForVente(txn, vente, userId, isAdding: false);
    }
  }

  // Méthode pour grouper les ventes par client et date
  Map<String, List<Vente>> groupVentesByClientAndDate(List<Vente> ventes) {
    final Map<String, List<Vente>> grouped = {};
    
    for (final vente in ventes) {
      final key = '${vente.clientId}-${vente.dateVente.year}-${vente.dateVente.month}-${vente.dateVente.day}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(vente);
    }
    
    return grouped;
  }
}