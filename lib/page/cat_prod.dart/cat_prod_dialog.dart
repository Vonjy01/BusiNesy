import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/models/categorie_produit_model.dart';

class CategorieDialog extends ConsumerStatefulWidget {
  final CategorieProduit? categorie;
  final String entrepriseId;
  
  const CategorieDialog({
    super.key, 
    this.categorie,
    required this.entrepriseId,
  });

  @override
  ConsumerState<CategorieDialog> createState() => _CategorieDialogState();
}

class _CategorieDialogState extends ConsumerState<CategorieDialog> {
  final _libelleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
          decoration: const InputDecoration(
            labelText: 'Nom de la catégorie',
            border: OutlineInputBorder(),
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleSubmit(context, isEditing),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(buttonText),
        ),
      ],
    );
  }

  Future<void> _handleSubmit(BuildContext context, bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final controller = ref.read(categorieProduitControllerProvider.notifier);
      
      if (isEditing) {
        // Logique de modification
        final updated = widget.categorie!.copyWith(
          libelle: _libelleController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await controller.updateCategorie(updated);
      } else {
        // Logique d'ajout
        await controller.addCategorie(_libelleController.text.trim(), widget.entrepriseId);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}