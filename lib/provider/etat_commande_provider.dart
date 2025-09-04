import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/command_model.dart';
import 'package:project6/models/etat_commande.dart';
import 'package:project6/services/database_helper.dart';

final etatCommandeProvider = FutureProvider<List<EtatCommande>>((ref) async {
  final dbHelper = DatabaseHelper.instance;
  final db = await dbHelper.database;

  final etats = await db.query('etat_commande');
  return etats.map((e) => EtatCommande.fromMap(e)).toList();
});
