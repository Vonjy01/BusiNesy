import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';

class DatabaseBackupPage extends StatefulWidget {
  const DatabaseBackupPage({super.key});

  @override
  State<DatabaseBackupPage> createState() => _DatabaseBackupPageState();
}

class _DatabaseBackupPageState extends State<DatabaseBackupPage> {
  String _status = '';

  Future<String> get _localDatabasePath async {
    final db = await DatabaseHelper.instance.database;
    return db.path;
  }
Future<String> get _dbFilePath async {
  final dir = await getApplicationDocumentsDirectory();
  return join(dir.path, DatabaseHelper.dbName); // même nom que dans DatabaseHelper
}

  /// Chemin de sauvegarde : dossier "BusiNesyBackup" dans le stockage externe
  Future<String> get _backupFolderPath async {
    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())!;
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final backupDir = Directory(join(dir.path, 'BusiNesyBackup'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }
Future<void> backupDatabase() async {
  try {
    final dbPath = await _dbFilePath;

    // ✅ Fermer la DB avant de copier pour éviter un fichier partiel
    await DatabaseHelper.instance.close();
    DatabaseHelper.instance.resetDatabase();

    final backupDir = await _backupFolderPath;
    final backupPath = join(backupDir, 'BusiNesy_backup.db');

    await File(dbPath).copy(backupPath);

    setState(() {
      _status = 'Sauvegarde réussie : $backupPath';
    });

    // Réouvrir pour continuer à travailler après sauvegarde
    await DatabaseHelper.instance.database;

  } catch (e) {
    setState(() {
      _status = 'Erreur lors de la sauvegarde : $e';
    });
  }
}

Future<void> restoreDatabase() async {
  try {
    final dbPath = await _dbFilePath;
    final backupDir = await _backupFolderPath;
    final backupPath = join(backupDir, 'BusiNesy_backup.db');

    if (!await File(backupPath).exists()) {
      setState(() {
        _status = 'Aucun fichier de sauvegarde trouvé.';
      });
      return;
    }

    // Fermer et réinitialiser la DB actuelle
    await DatabaseHelper.instance.close();
    DatabaseHelper.instance.resetDatabase();

    // Supprimer l’ancienne DB physique
    if (await File(dbPath).exists()) {
      await File(dbPath).delete();
    }

    // Copier le fichier de sauvegarde
    await File(backupPath).copy(dbPath);

    // Réouvrir la nouvelle DB
    await DatabaseHelper.instance.database;

    setState(() {
      _status = 'Restauration réussie et base actualisée ✅';
    });

  } catch (e) {
    setState(() {
      _status = 'Erreur lors de la restauration : $e';
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sauvegarde / Restauration DB'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Sauvegarder la base de données'),
              onPressed: backupDatabase,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Restaurer la base de données'),
              onPressed: restoreDatabase,
            ),
            const SizedBox(height: 30),
            Text(
              _status,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            ElevatedButton.icon(
  icon: const Icon(Icons.bug_report),
  label: const Text('Debug DB'),
  onPressed: () async {
    await DatabaseHelper.instance.debugDatabase();
    setState(() {
      _status = 'Debug exécuté (voir console)';
    });
  },
),

          ],
        ),
      ),
    );
  }
}
