import 'package:project6/models/entreprise_model.dart';
import 'package:project6/services/database_helper.dart';

class EntrepriseService {
  final DatabaseHelper _dbHelper;

  EntrepriseService(this._dbHelper);

  Future<Entreprise?> getCurrentEntreprise(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'entreprises',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return maps.isNotEmpty ? Entreprise.fromMap(maps.first) : null;
  }

  Future<void> setCurrentEntreprise(Entreprise entreprise) async {
    final db = await _dbHelper.database;
    await db.update(
      'entreprises',
      entreprise.toMap(),
      where: 'id = ?',
      whereArgs: [entreprise.id],
    );
  }
}