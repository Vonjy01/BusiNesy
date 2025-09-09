import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project6/models/user_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  final _uuid = Uuid();
  final _secureStorage = const FlutterSecureStorage();
  final _dbHelper = DatabaseHelper.instance;

  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('first_run') ?? true;
  }

  Future<void> setFirstRunComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_run', false);
  }

  @override
  Future<User?> build() async {
    final userId = await _secureStorage.read(key: 'user_id');
    if (userId == null) return null;

    final db = await _dbHelper.database;
    final users = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (users.isEmpty) return null;

    return User.fromJson({
      'id': users.first['id'].toString(),
      'nom': users.first['nom'].toString(),
      'telephone': users.first['telephone'].toString(),
      'mot_de_passe': users.first['mot_de_passe'].toString(),
    });
  }

  Future<void> login(String telephone, String motDePasse) async {
    state = const AsyncLoading();
    try {
      final db = await _dbHelper.database;
      final users = await db.query(
        'users',
        where: 'telephone = ? AND mot_de_passe = ?',
        whereArgs: [telephone, motDePasse],
      );

      if (users.isEmpty) throw Exception('Identifiants incorrects');

      final user = User.fromJson({
        'id': users.first['id'].toString(),
        'nom': users.first['nom'].toString(),
        'telephone': users.first['telephone'].toString(),
        'mot_de_passe': users.first['mot_de_passe'].toString(),
      });

      await _secureStorage.write(key: 'user_id', value: user.id);
      state = AsyncData(user);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
  Future<void> register({
    required String nom,
    required String telephone,
    required String motDePasse,
  }) async {
    state = const AsyncLoading();
    try {
      final db = await _dbHelper.database;
      
      // Vérifie si le numéro existe déjà
      final existingUsers = await db.query(
        'users',
        where: 'telephone = ?',
        whereArgs: [telephone],
      );
      
      if (existingUsers.isNotEmpty) {
        throw Exception('Ce numéro est déjà utilisé');
      }

      final user = User(
        id: _uuid.v4(),
        nom: nom.trim(),
        telephone: telephone.trim(),
        motDePasse: motDePasse, // On garde le mot de passe en clair comme demandé
      );

      await db.insert('users', {
        'id': user.id,
        'nom': user.nom,
        'telephone': user.telephone,
        'mot_de_passe': user.motDePasse,
      });

      await _secureStorage.write(key: 'user_id', value: user.id);
      state = AsyncData(user);
      
      // On ne crée plus d'entreprise automatiquement ici
      // L'utilisateur sera redirigé vers la page de création d'entreprise
      
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
 Future<void> logout() async {
  await _secureStorage.delete(key: 'user_id');
  state = const AsyncData(null);
}
}