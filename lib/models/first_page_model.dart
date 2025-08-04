import 'package:shared_preferences/shared_preferences.dart';

Future<bool> isFirstRun() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('first_run') ?? true;
}

Future<void> setFirstRunComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('first_run', false);
}