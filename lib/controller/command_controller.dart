// commande_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/command_model.dart';
import 'package:project6/models/etat_commande.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:uuid/uuid.dart';

final commandeControllerProvider = AsyncNotifierProvider<CommandeController, List<Commande>>(
  CommandeController.new,
);

class CommandeController extends AsyncNotifier<List<Commande>> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Commande>> build() async {
    return await loadCommandes();
  }

  Future<List<Commande>> loadCommandes() async {
    try {
      final db = await _dbHelper.database;
      final commandes = await db.query('commandes');
      return commandes.map(Commande.fromMap).toList();
    } catch (e, stack) {
      print('Error loading commandes: $e\n$stack');
      rethrow;
    }
  }

  // AJOUTEZ CETTE MÉTHODE
  Future<void> updateCommandeEtat(String commandeId, int newEtat) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      await db.update(
        'commandes',
        {
          'etat': newEtat,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [commandeId],
      );

      state = await AsyncValue.guard(loadCommandes);
    } catch (e, stack) {
      print('Error updating commande etat: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
Future<void> addCommande(Commande commande, String userId) async {
  try {
    state = const AsyncValue.loading();
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Insérer la commande
      await txn.insert('commandes', commande.toMap());

      // Vérifier si l'état est déjà Réçu/Incomplet et qu'une quantité est saisie
      if ((commande.etat == 2 || commande.etat == 3) &&
          commande.quantiteRecue != null &&
          commande.quantiteRecue! > 0) {
        
        // Charger le produit
        final produitResult = await txn.query(
          'produits',
          where: 'id = ?',
          whereArgs: [commande.produitId],
        );
        if (produitResult.isNotEmpty) {
          final produitActuel = Produit.fromMap(produitResult.first);

          // Mettre à jour le stock
          final nouveauStock = produitActuel.stock + commande.quantiteRecue!;
          await txn.update(
            'produits',
            {
              'stock': nouveauStock,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [commande.produitId],
          );

          // Ajouter dans l’historique des stocks
          await txn.insert('historique_stocks', {
            'produit_id': commande.produitId,
            'quantite': commande.quantiteRecue!,
            'defectueux': 0,
            'user_id': userId,
            'entreprise_id': commande.entrepriseId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    });

    state = await AsyncValue.guard(loadCommandes);
  } catch (e, stack) {
    print('Error adding commande: $e\n$stack');
    state = AsyncValue.error(e, stack);
    rethrow;
  }
}

// commande_controller.dart
// commande_controller.dart - Mettez à jour la méthode updateCommande
// commande_controller.dart - Version corrigée
Future<void> updateCommande(Commande commande, String userId) async {
  try {
    state = const AsyncValue.loading();
    final db = await _dbHelper.database;

    // Récupérer l'ancienne commande pour vérifier l'état précédent
    final ancienneCommandeResult = await db.query(
      'commandes',
      where: 'id = ?',
      whereArgs: [commande.id],
    );
    
    final ancienneCommande = ancienneCommandeResult.isNotEmpty 
        ? Commande.fromMap(ancienneCommandeResult.first) 
        : null;

    await db.transaction((txn) async {
      // Mettre à jour la commande
      await txn.update(
        'commandes',
        commande.toMap(),
        where: 'id = ?',
        whereArgs: [commande.id],
      );

      // Récupérer le produit actuel
      final produitResult = await txn.query(
        'produits',
        where: 'id = ?',
        whereArgs: [commande.produitId],
      );

      if (produitResult.isEmpty) return;
      final produitActuel = Produit.fromMap(produitResult.first);

      // Gestion des transitions d'état
      if (ancienneCommande != null) {
        // CAS 1: Ancien état était Réçu (2) ou Incomplet (3) et nouveau état est Annulé (4)
        if ((ancienneCommande.etat == 2 || ancienneCommande.etat == 3) && 
            commande.etat == 4 && 
            ancienneCommande.quantiteRecue != null && 
            ancienneCommande.quantiteRecue! > 0) {
          
          // Retirer la quantité qui avait été ajoutée
          final nouveauStock = produitActuel.stock - ancienneCommande.quantiteRecue!;
          
          await txn.update(
            'produits',
            {
              'stock': nouveauStock,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [commande.produitId],
          );

          // Ajouter à l'historique des stocks (négatif pour indiquer retrait)
          await txn.insert('historique_stocks', {
            'produit_id': commande.produitId,
            'quantite': -ancienneCommande.quantiteRecue!,
            'defectueux': 0,
            'user_id': userId,
            'entreprise_id': commande.entrepriseId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // CAS 2: Ancien état était Annulé (4) et nouveau état est Réçu (2) ou Incomplet (3)
        else if (ancienneCommande.etat == 4 && 
                 (commande.etat == 2 || commande.etat == 3) && 
                 commande.quantiteRecue != null && 
                 commande.quantiteRecue! > 0) {
          
          // Ajouter la quantité reçue au stock
          final nouveauStock = produitActuel.stock + commande.quantiteRecue!;
          
          await txn.update(
            'produits',
            {
              'stock': nouveauStock,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [commande.produitId],
          );

          // Ajouter à l'historique des stocks
          await txn.insert('historique_stocks', {
            'produit_id': commande.produitId,
            'quantite': commande.quantiteRecue!,
            'defectueux': 0,
            'user_id': userId,
            'entreprise_id': commande.entrepriseId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // CAS 3: Changement de quantité reçue pour un état Réçu/Incomplet
        else if ((ancienneCommande.etat == 2 || ancienneCommande.etat == 3) && 
                 (commande.etat == 2 || commande.etat == 3) && 
                 ancienneCommande.quantiteRecue != commande.quantiteRecue) {
          
          // Calculer la différence
          final difference = (commande.quantiteRecue ?? 0) - (ancienneCommande.quantiteRecue ?? 0);
          final nouveauStock = produitActuel.stock + difference;
          
          await txn.update(
            'produits',
            {
              'stock': nouveauStock,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [commande.produitId],
          );

          // Ajouter la différence à l'historique
          if (difference != 0) {
            await txn.insert('historique_stocks', {
              'produit_id': commande.produitId,
              'quantite': difference,
              'defectueux': 0,
              'user_id': userId,
              'entreprise_id': commande.entrepriseId,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }

        // CAS 4: Passage d'En attente (1) à Réçu/Incomplet (2/3)
        else if (ancienneCommande.etat == 1 && 
                 (commande.etat == 2 || commande.etat == 3) && 
                 commande.quantiteRecue != null && 
                 commande.quantiteRecue! > 0) {
          
          // Ajouter la quantité reçue au stock
          final nouveauStock = produitActuel.stock + commande.quantiteRecue!;
          
          await txn.update(
            'produits',
            {
              'stock': nouveauStock,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [commande.produitId],
          );

          // Ajouter à l'historique des stocks
          await txn.insert('historique_stocks', {
            'produit_id': commande.produitId,
            'quantite': commande.quantiteRecue!,
            'defectueux': 0,
            'user_id': userId,
            'entreprise_id': commande.entrepriseId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // CAS 5: Passage de Réçu/Incomplet (2/3) à En attente (1)
        else if ((ancienneCommande.etat == 2 || ancienneCommande.etat == 3) && 
                 commande.etat == 1 && 
                 ancienneCommande.quantiteRecue != null && 
                 ancienneCommande.quantiteRecue! > 0) {
          
          // Retirer la quantité qui avait été ajoutée
          final nouveauStock = produitActuel.stock - ancienneCommande.quantiteRecue!;
          
          await txn.update(
            'produits',
            {
              'stock': nouveauStock,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [commande.produitId],
          );

          // Ajouter à l'historique des stocks (négatif pour indiquer retrait)
          await txn.insert('historique_stocks', {
            'produit_id': commande.produitId,
            'quantite': -ancienneCommande.quantiteRecue!,
            'defectueux': 0,
            'user_id': userId,
            'entreprise_id': commande.entrepriseId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
      
      // CAS 6: Nouvelle commande (pas d'ancienne commande) qui passe directement à Réçu/Incomplet
      else if (ancienneCommande == null && 
               (commande.etat == 2 || commande.etat == 3) && 
               commande.quantiteRecue != null && 
               commande.quantiteRecue! > 0) {
        
        // Ajouter la quantité reçue au stock
        final nouveauStock = produitActuel.stock + commande.quantiteRecue!;
        
        await txn.update(
          'produits',
          {
            'stock': nouveauStock,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [commande.produitId],
        );

        // Ajouter à l'historique des stocks
        await txn.insert('historique_stocks', {
          'produit_id': commande.produitId,
          'quantite': commande.quantiteRecue!,
          'defectueux': 0,
          'user_id': userId,
          'entreprise_id': commande.entrepriseId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    });

    state = await AsyncValue.guard(loadCommandes);
  } catch (e, stack) {
    print('Error updating commande: $e\n$stack');
    state = AsyncValue.error(e, stack);
    rethrow;
  }
}

  Future<void> deleteCommande(String id) async {
    try {
      state = const AsyncValue.loading();
      final db = await _dbHelper.database;

      await db.delete(
        'commandes',
        where: 'id = ?',
        whereArgs: [id],
      );

      state = await AsyncValue.guard(loadCommandes);
    } catch (e, stack) {
      print('Error deleting commande: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}