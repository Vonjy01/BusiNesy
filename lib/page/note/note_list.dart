import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/controller/note_controller.dart';
import 'package:project6/models/note_model.dart';
import 'package:project6/page/note/edit_note_dialog.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';

class NoteList extends ConsumerStatefulWidget {
  const NoteList({super.key});

  @override
  ConsumerState<NoteList> createState() => _NoteListState();
}

class _NoteListState extends ConsumerState<NoteList> {
  String? _lastLoadedEntrepriseId;
  String? _currentSearchQuery;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotesIfNeeded();
    });
  }

  void _loadNotesIfNeeded() {
    final activeEntreprise = ref.read(activeEntrepriseProvider).value;
    if (activeEntreprise != null && _lastLoadedEntrepriseId != activeEntreprise.id) {
      _lastLoadedEntrepriseId = activeEntreprise.id;
      _currentSearchQuery = null;
      ref.read(noteControllerProvider.notifier).loadNotes(activeEntreprise.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final activeEntreprise = ref.watch(activeEntrepriseProvider).value;
    final notesAsync = ref.watch(noteControllerProvider);

    if (activeEntreprise != null && _lastLoadedEntrepriseId != activeEntreprise.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lastLoadedEntrepriseId = activeEntreprise.id;
        _currentSearchQuery = null;
        ref.read(noteControllerProvider.notifier).loadNotes(activeEntreprise.id);
      });
    }

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Erreur: $error'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Utilisateur non connecté')),
          );
        }

        return Scaffold(
          drawer: AppDrawer(user: user),
          body: Column(
            children: [
              Header(
                title: 'Bloc-notes',
                actions: [
                  if (activeEntreprise != null) ...[
                    if (_currentSearchQuery != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: color_white),
                        onPressed: () {
                          setState(() => _currentSearchQuery = null);
                          ref.read(noteControllerProvider.notifier).loadNotes(activeEntreprise.id, forceReload: true);
                        },
                        tooltip: 'Effacer la recherche',
                      ),
                    IconButton(
                      icon: const Icon(Icons.search, color: color_white),
                      onPressed: () => _showSearchDialog(context, ref, activeEntreprise.id),
                    ),
                  ],
                ],
              ),

              if (activeEntreprise == null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Veuillez sélectionner une entreprise pour voir les notes',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),

              Expanded(
                child: activeEntreprise == null
                    ? const SizedBox()
                    : notesAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Text(
                            'Erreur: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        data: (notes) {
                          if (notes.isEmpty) {
                            return _buildEmptyState(activeEntreprise.id, user.id);
                          }

                          return _buildNotesList(notes, activeEntreprise.id, user.id);
                        },
                      ),
              ),
            ],
          ),
         floatingActionButton: activeEntreprise == null
    ? null
    : FloatingActionButton(
        onPressed: () => _createNewNote(context, activeEntreprise.id, user.id),
        backgroundColor: background_theme,
        heroTag: null, // ← AJOUTEZ CETTE LIGNE
        child: const Icon(Icons.add, color: Colors.white),
      ),
        );
      },
    );
  }

  Widget _buildEmptyState(String entrepriseId, String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            _currentSearchQuery != null
                ? 'Aucune note trouvée pour "${_currentSearchQuery!}"'
                : 'Aucune note pour le moment',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _createNewNote(context, entrepriseId, userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: background_theme,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Créer votre première note',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes, String entrepriseId, String userId) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(note, entrepriseId, userId);
      },
    );
  }

  Widget _buildNoteCard(Note note, String entrepriseId, String userId) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: background_theme.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.note,
            color: background_theme,
            size: 24,
          ),
        ),
        title: Text(
          note.titre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.text != null && note.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  note.text!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            Text(
              _formatDate(note.updatedAt ?? note.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handlePopupSelection(value, note, entrepriseId, userId),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
        onTap: () => _editNote(context, note, entrepriseId, userId),
      ),
    );
  }

  void _createNewNote(BuildContext context, String entrepriseId, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditPage(
          entrepriseId: entrepriseId,
          userId: userId,
        ),
      ),
    ).then((_) {
      if (_lastLoadedEntrepriseId != null) {
        ref.read(noteControllerProvider.notifier).loadNotes(_lastLoadedEntrepriseId!, forceReload: true);
      }
    });
  }

  void _editNote(BuildContext context, Note note, String entrepriseId, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditPage(
          note: note,
          entrepriseId: entrepriseId,
          userId: userId,
        ),
      ),
    ).then((_) {
      if (_lastLoadedEntrepriseId != null) {
        ref.read(noteControllerProvider.notifier).loadNotes(_lastLoadedEntrepriseId!, forceReload: true);
      }
    });
  }

  void _handlePopupSelection(String value, Note note, String entrepriseId, String userId) {
    switch (value) {
      case 'edit':
        _editNote(context, note, entrepriseId, userId);
        break;
      case 'delete':
        _confirmDelete(context, note, entrepriseId);
        break;
    }
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref, String entrepriseId) {
    final searchController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Rechercher une note"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Titre, contenu...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (value) async {
                    if (value.isNotEmpty) {
                      setState(() => isLoading = true);
                      await ref.read(noteControllerProvider.notifier).searchNotesMulti(entrepriseId, value);
                      setState(() => isLoading = false);
                      if (context.mounted) {
                        setState(() => _currentSearchQuery = value);
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
                if (isLoading) 
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () {
                  setState(() => _currentSearchQuery = null);
                  ref.read(noteControllerProvider.notifier).loadNotes(entrepriseId, forceReload: true);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Afficher tout"),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final query = searchController.text.trim();
                  setState(() => isLoading = true);
                  
                  if (query.isNotEmpty) {
                    await ref.read(noteControllerProvider.notifier).searchNotesMulti(entrepriseId, query);
                    setState(() => _currentSearchQuery = query);
                  } else {
                    await ref.read(noteControllerProvider.notifier).loadNotes(entrepriseId);
                    setState(() => _currentSearchQuery = null);
                  }
                  
                  setState(() => isLoading = false);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Rechercher"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Note note, String entrepriseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${note.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteNote(context, note, entrepriseId);
    }
  }

  Future<void> _deleteNote(BuildContext context, Note note, String entrepriseId) async {
    try {
      final controller = ref.read(noteControllerProvider.notifier);
      await controller.deleteNote(note.id, entrepriseId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${note.titre}" a été supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}