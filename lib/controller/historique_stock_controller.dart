import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/services/database_helper.dart';

final historiqueStockProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, entrepriseId) async {
  final db = await DatabaseHelper.instance.database;
  
  final result = await db.rawQuery('''
    SELECT hs.*, 
           p.nom as produit_nom, 
           u.nom as user_nom
    FROM historique_stocks hs
    LEFT JOIN produits p ON hs.produit_id = p.id
    LEFT JOIN users u ON hs.user_id = u.id
    WHERE hs.entreprise_id = ?
    ORDER BY hs.created_at DESC
  ''', [entrepriseId]);

  return result;
});