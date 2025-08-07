import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static const String _dbName = 'Gestock.db';
  static const int _dbVersion = 4;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);

    bool exists = await databaseExists(path);
  if (!exists) {
    try {
      await Directory(dirname(path)).create(recursive: true);
      
      // Essayez de copier depuis les assets seulement si la base n'existe pas
      try {
        ByteData data = await rootBundle.load("assets/database/$_dbName");
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        print("Aucune base initiale trouvée, création d'une base vide");
        // Crée une base vide si aucun fichier dans assets
        await openDatabase(path);
      }
    } catch (e) {
      print("Erreur lors de l'initialisation : $e");
      rethrow;
    }
  }
    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
Future<void> debugDatabase() async {
  try {
    final db = await database;
    final users = await db.query('users');
    final entreprises = await db.query('entreprises');
    
    debugPrint('=== DEBUG DATABASE ===');
    debugPrint('Utilisateurs: ${users.length}');
    debugPrint('Entreprises: ${entreprises.length}');
    if (entreprises.isNotEmpty) {
      debugPrint('Dernière entreprise: ${entreprises.last}');
    }
  } catch (e) {
    debugPrint('Erreur debugDatabase: $e');
  }
}
}
