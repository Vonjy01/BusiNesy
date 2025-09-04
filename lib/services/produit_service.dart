import 'package:project6/models/produits_model.dart';
import 'package:project6/services/database_helper.dart';

class ProduitService {
  final DatabaseHelper _dbHelper;

  ProduitService(this._dbHelper);

  Future<List<Produit>> getAll(String entrepriseId) async {
    final db = await _dbHelper.database;
    final produits = await db.query(
      'produits',
      where: 'entreprise_id = ?',
      whereArgs: [entrepriseId],
    );
    return produits.map((p) => Produit.fromMap(p)).toList();
  }

  Future<void> create(Produit produit) async {
    final db = await _dbHelper.database;
    await db.insert('produits', {
      'id': produit.id,
      'nom': produit.nom,
      'stock': produit.stock,
      'prix_vente': produit.prixVente,
      'prix_achat': produit.prixAchat,
      'benefice': null, // Ajouté pour correspondre au schéma
      'entreprise_id': produit.entrepriseId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}