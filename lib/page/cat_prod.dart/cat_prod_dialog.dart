// lib/page/categorie_produit/categorie_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/models/categorie_produit_model.dart';

class CategorieDialog extends ConsumerStatefulWidget {
  final CategorieProduit? categorie;
  
  const CategorieDialog({super.key, this.categorie});

  @override
  ConsumerState<CategorieDialog> createState() => _CategorieDialogState();
}

class _CategorieDialogState extends ConsumerState<CategorieDialog> {
  final _libelleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Si on a une catégorie, c'est une modification
    if (widget.categorie != null) {
      _libelleController.text = widget.categorie!.libelle;
    }
  }

  @override
  void dispose() {
    _libelleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categorie != null;
    final title = isEditing ? 'Modifier Catégorie' : 'Nouvelle Catégorie';
    final buttonText = isEditing ? 'Sauvegarder' : 'Ajouter';

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _libelleController,
          decoration: InputDecoration(
            labelText: 'Nom de la catégorie',
            border: const OutlineInputBorder(),
            hintText: 'Ex: Électronique, Alimentaire...',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ce champ est obligatoire';
            }
            return null;
          },
          maxLength: 50,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => _handleSubmit(context, isEditing),
          child: Text(buttonText),
        ),
      ],
    );
  }

  Future<void> _handleSubmit(BuildContext context, bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (isEditing) {
        // Logique de modification
        final updated = widget.categorie!.copyWith(
          libelle: _libelleController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await ref.read(categorieProduitControllerProvider.notifier)
            .updateCategorie(updated);
      } else {
        // Logique d'ajout
        await ref.read(categorieProduitControllerProvider.notifier)
            .addCategorie(_libelleController.text.trim());
      }

      if (mounted) Navigator.pop(context);
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
}