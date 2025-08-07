import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/services/database_helper.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});