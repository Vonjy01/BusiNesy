import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return DatabaseHelper.instance.database;
});