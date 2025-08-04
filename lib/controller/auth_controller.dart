import 'package:project6/models/user_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<User?> build() async {
    // Vérifier d'abord en mémoire si l'utilisateur est déjà chargé
    if (state is AsyncData && state.value != null) {
      return state.value;
    }
    
    // Sinon, vérifier dans la base de données
    final db = await DatabaseHelper.instance.database;
    final users = await db.query('users', limit: 1);
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
      final db = await DatabaseHelper.instance.database;
      final users = await db.query(
        'users',
        where: 'telephone = ? AND mot_de_passe = ?',
        whereArgs: [telephone, motDePasse],
      );

      if (users.isEmpty) throw Exception('Identifiants incorrects');
      
      state = AsyncData(User.fromJson({
        'id': users.first['id'],
        'nom': users.first['nom'],
        'telephone': users.first['telephone'],
        'numero': users.first['numero'],
        'mot_de_passe': users.first['mot_de_passe'],
      }));
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
    state = const AsyncValue.loading();
    try {
      final db = await DatabaseHelper.instance.database;
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: nom,
        telephone: telephone,
        motDePasse: motDePasse,
      );

      await db.insert('users', {
        'id': user.id,
        'nom': user.nom,
        'telephone': user.telephone,
        'mot_de_passe': user.motDePasse,
      });

      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}