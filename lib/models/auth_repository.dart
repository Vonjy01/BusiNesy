import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project6/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthRepository(this._prefs);

  Future<void> saveUser(User user) async {
    await _secureStorage.write(key: 'user_id', value: user.id);
    await _secureStorage.write(key: 'user_nom', value: user.nom);
    await _secureStorage.write(key: 'user_telephone', value: user.telephone);
    await _secureStorage.write(key: 'user_motDePasse', value: user.motDePasse);
  }

  Future<User?> getCurrentUser() async {
    final id = await _secureStorage.read(key: 'user_id');
    if (id == null) return null;
    
    return User(
      id: id,
      nom: (await _secureStorage.read(key: 'user_nom'))!,
      telephone: (await _secureStorage.read(key: 'user_telephone'))!,
      motDePasse: (await _secureStorage.read(key: 'user_motDePasse'))!,
    );
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
    await _prefs.setBool('first_run', false);
  }

  Future<bool> isFirstRun() async => _prefs.getBool('first_run') ?? true;
  Future<void> setFirstRunComplete() async => _prefs.setBool('first_run', false);
}