import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/note_controller.dart';
import 'package:project6/models/note_model.dart';
import 'package:project6/utils/constant.dart';

class NoteEditPage extends ConsumerStatefulWidget {
  final Note? note;
  final String entrepriseId;
  final String userId;

  const NoteEditPage({
    super.key,
    this.note,
    required this.entrepriseId,
    required this.userId,
  });

  @override
  ConsumerState<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends ConsumerState<NoteEditPage> {
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titreController.text = widget.note!.titre;
      _contenuController.text = widget.note!.text ?? '';
    }
    
    _titreController.addListener(_checkChanges);
    _contenuController.addListener(_checkChanges);
  }

  void _checkChanges() {
    final hasChanges = widget.note == null 
        ? _titreController.text.isNotEmpty || _contenuController.text.isNotEmpty
        : _titreController.text != widget.note!.titre || 
          _contenuController.text != (widget.note!.text ?? '');
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _contenuController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter sans sauvegarder ?'),
        content: const Text('Vous avez des modifications non sauvegardées. Voulez-vous vraiment quitter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              _saveNote();
              Navigator.pop(context, true);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'Nouvelle note' : 'Modifier la note'),
          backgroundColor: background_theme,
          foregroundColor: Colors.white,
          actions: [
            if (_hasChanges) ...[
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isEditing ? null : _saveNote,
                tooltip: 'Sauvegarder',
              ),
            ],
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'save':
                    _saveNote();
                    break;
                  case 'delete':
                    if (widget.note != null) _confirmDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (_hasChanges) 
                  const PopupMenuItem(
                    value: 'save',
                    child: ListTile(
                      leading: Icon(Icons.save),
                      title: Text('Sauvegarder'),
                    ),
                  ),
                if (widget.note != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titreController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Titre de la note...',
                  hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                maxLines: 1,
              ),
              
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 8),
              
              if (widget.note != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Modifiée: ${_formatDate(widget.note!.updatedAt ?? widget.note!.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              Expanded(
                child: TextField(
                  controller: _contenuController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Commencez à écrire votre note...',
                    hintStyle: TextStyle(fontSize: 16),
                  ),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
       floatingActionButton: _hasChanges && !_isEditing
    ? FloatingActionButton(
        onPressed: _saveNote,
        backgroundColor: background_theme,
        heroTag: null, // ← AJOUTEZ CETTE LIGNE
        child: const Icon(Icons.save, color: Colors.white),
      )
    : null,
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_titreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le titre est obligatoire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isEditing = true);

    try {
      final controller = ref.read(noteControllerProvider.notifier);
      
      if (widget.note != null) {
        final updatedNote = widget.note!.copyWith(
          titre: _titreController.text.trim(),
          text: _contenuController.text.trim().isEmpty ? null : _contenuController.text.trim(),
        );
        await controller.updateNote(updatedNote);
      } else {
        await controller.addNote(
          titre: _titreController.text.trim(),
          text: _contenuController.text.trim().isEmpty ? null : _contenuController.text.trim(),
          userId: widget.userId,
          entrepriseId: widget.entrepriseId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.note != null ? 'Note modifiée' : 'Note créée'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() => _hasChanges = false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEditing = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${widget.note!.titre}" ?'),
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
      await _deleteNote();
    }
  }

  Future<void> _deleteNote() async {
    try {
      final controller = ref.read(noteControllerProvider.notifier);
      await controller.deleteNote(widget.note!.id, widget.entrepriseId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note supprimée'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}