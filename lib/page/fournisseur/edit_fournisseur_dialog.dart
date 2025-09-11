import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/fournisseur_controller.dart';
import 'package:project6/models/fournisseur_model.dart';

class EditFournisseurDialog extends ConsumerStatefulWidget {
  final Fournisseur? fournisseur;
  final String entrepriseId;

  const EditFournisseurDialog({
    super.key,
    this.fournisseur,
    required this.entrepriseId,
  });

  @override
  ConsumerState<EditFournisseurDialog> createState() => _EditFournisseurDialogState();
}

class _EditFournisseurDialogState extends ConsumerState<EditFournisseurDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  late TextEditingController _adresseController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.fournisseur?.nom ?? '');
    _telephoneController = TextEditingController(text: widget.fournisseur?.telephone ?? '');
    _emailController = TextEditingController(text: widget.fournisseur?.email ?? '');
    _adresseController = TextEditingController(text: widget.fournisseur?.adresse ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.fournisseur != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier Fournisseur' : 'Nouveau Fournisseur'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _submitForm(ref),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }

  Future<void> _submitForm(WidgetRef ref) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final controller = ref.read(fournisseurControllerProvider.notifier);
        
        if (widget.fournisseur != null) {
          // Mise à jour du fournisseur existant
          final updatedFournisseur = widget.fournisseur!.copyWith(
            nom: _nomController.text.trim(),
            telephone: _telephoneController.text.trim().isEmpty 
                ? null 
                : _telephoneController.text.trim(),
            email: _emailController.text.trim().isEmpty 
                ? null 
                : _emailController.text.trim(),
            adresse: _adresseController.text.trim().isEmpty 
                ? null 
                : _adresseController.text.trim(),
          );

          await controller.updateFournisseur(updatedFournisseur);
        } else {
          // Création d'un nouveau fournisseur
          await controller.addFournisseur(
            nom: _nomController.text.trim(),
            entrepriseId: widget.entrepriseId,
            telephone: _telephoneController.text.trim().isEmpty 
                ? null 
                : _telephoneController.text.trim(),
            email: _emailController.text.trim().isEmpty 
                ? null 
                : _emailController.text.trim(),
            adresse: _adresseController.text.trim().isEmpty 
                ? null 
                : _adresseController.text.trim(),
          );
        }

        if (mounted) {
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
          setState(() => _isLoading = false);
        }
      }
    }
  }
}