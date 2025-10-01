import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/models/note_model.dart';
import 'package:project6/services/database_helper.dart';
import 'package:uuid/uuid.dart';

final noteControllerProvider = AsyncNotifierProvider<NoteController, List<Note>>(
  NoteController.new,
);

class NoteController extends AsyncNotifier<List<Note>> {
  final _dbHelper = DatabaseHelper.instance;
  final _uuid = Uuid();
  String? _currentEntrepriseId;

  @override
  Future<List<Note>> build() async {
    return [];
  }

  Future<void> loadNotes(String entrepriseId, {bool forceReload = false}) async {
    if (!forceReload && _currentEntrepriseId == entrepriseId && state is! AsyncError) {
      return;
    }

    _currentEntrepriseId = entrepriseId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadNotes(entrepriseId: entrepriseId));
  }

  Future<List<Note>> _loadNotes({required String entrepriseId}) async {
    final db = await _dbHelper.database;

    final notes = await db.query(
      'notes',
      where: 'entreprise_id = ?',
      whereArgs: [entrepriseId],
      orderBy: 'updated_at DESC, created_at DESC',
    );

    return notes.map(Note.fromMap).toList();
  }

  Timer? _searchTimer;

  Future<void> searchNotesMulti(String entrepriseId, String query) async {
    _searchTimer?.cancel();
    
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final db = await _dbHelper.database;

        final notes = await db.query(
          'notes',
          where: 'entreprise_id = ? AND (LOWER(titre) LIKE ? OR LOWER(text) LIKE ?)',
          whereArgs: [
            entrepriseId,
            '%${query.toLowerCase()}%',
            '%${query.toLowerCase()}%',
          ],
          orderBy: 'updated_at DESC, created_at DESC',
        );

        state = AsyncData(notes.map(Note.fromMap).toList());
      } catch (e) {
        state = AsyncError(e, StackTrace.current);
      }
    });
  }

  Future<void> addNote({
    required String titre,
    required String? text,
    required String userId,
    required String entrepriseId,
  }) async {
    try {
      final db = await _dbHelper.database;

      final note = Note(
        id: _uuid.v4(),
        titre: titre.trim(),
        text: text?.trim(),
        userId: userId,
        entrepriseId: entrepriseId,
        createdAt: DateTime.now(),
      );

      await db.insert('notes', note.toMap());
      
      if (_currentEntrepriseId == entrepriseId) {
        state = await AsyncValue.guard(() => _loadNotes(entrepriseId: entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      final db = await _dbHelper.database;

      final updatedNote = note.copyWith(
        updatedAt: DateTime.now(),
      );

      await db.update(
        'notes',
        updatedNote.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );

      if (_currentEntrepriseId == note.entrepriseId) {
        state = await AsyncValue.guard(() => _loadNotes(entrepriseId: note.entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> deleteNote(String id, String entrepriseId) async {
    try {
      final db = await _dbHelper.database;

      await db.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (_currentEntrepriseId == entrepriseId) {
        state = await AsyncValue.guard(() => _loadNotes(entrepriseId: entrepriseId));
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<Note?> getNoteById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isEmpty ? null : Note.fromMap(result.first);
  }
}