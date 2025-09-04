import 'package:project6/models/command_model.dart';
import 'package:project6/models/etat_commande.dart';
import 'package:project6/services/database_helper.dart';

class CommandeService {
  final DatabaseHelper _dbHelper;

  CommandeService(this._dbHelper);

  Future<List<Commande>> getAll(String entrepriseId) async {
    final db = await _dbHelper.database;
    final commandes = await db.query(
      'commandes',
      where: 'entreprise_id = ?',
      whereArgs: [entrepriseId],
      orderBy: 'date_commande DESC',
    );
    return commandes.map((c) => Commande.fromMap(c)).toList();
  }

  Future<Commande?> getById(String id) async {
    final db = await _dbHelper.database;
    final commandes = await db.query(
      'commandes',
      where: 'id = ?',
      whereArgs: [id],
    );
    return commandes.isNotEmpty ? Commande.fromMap(commandes.first) : null;
  }
  Future<void> create(Commande commande) async {
    final db = await _dbHelper.database;
    await db.insert('commandes', {
      'id': commande.id,
      'fournisseur_id': commande.fournisseurId,
      'produit_id': commande.produitId,
      'quantite_command': commande.quantiteCommandee,
      'quantite_recu': commande.quantiteRecue,
      'prix_unitaire': commande.prixUnitaire, // Accepte null
      'date_commande': commande.dateCommande.toIso8601String(),
      'date_arrivee': commande.dateArrivee?.toIso8601String(),
      'etat': commande.etat,
      'entreprise_id': commande.entrepriseId,
    });
  }

  Future<void> update(Commande commande) async {
    final db = await _dbHelper.database;
    await db.update(
      'commandes',
      commande.toMap(),
      where: 'id = ?',
      whereArgs: [commande.id],
    );
  }

  Future<void> validerReception({
    required String commandeId,
    required int quantiteRecue,
    required String userId,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Récupérer la commande
      final commande = await getById(commandeId);
      if (commande == null) return;

      // 2. Mettre à jour la commande
      await txn.update(
        'commandes',
        {
          'quantite_recu': quantiteRecue,
          'etat': 2, // État "Reçu"
          'date_arrivee': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [commandeId],
      );

      // 3. Mettre à jour le stock
      await txn.rawUpdate(
        'UPDATE produits SET stock = stock + ? WHERE id = ?',
        [quantiteRecue, commande.produitId],
      );

      // 4. Historique des stocks
      await txn.insert('historique_stocks', {
        'produit_id': commande.produitId,
        'quantite': quantiteRecue,
        'fournisseur_id': commande.fournisseurId,
        'date_ajout': DateTime.now().toIso8601String(),
        'user_id': userId,
        'entreprise_id': commande.entrepriseId,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<List<EtatCommande>> getEtatsCommande() async {
    final db = await _dbHelper.database;
    final etats = await db.query('etat_commande');
    return etats.map((e) => EtatCommande.fromMap(e)).toList();
  }
}