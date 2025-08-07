import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/controller/fournisseur_controller.dart';
import 'package:project6/models/fournisseur_model.dart';

class EditFournisseurDialog extends ConsumerStatefulWidget {
  final Fournisseur? fournisseur;

  const EditFournisseurDialog({
    super.key,
    this.fournisseur,
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
    final activeEntreprise = ref.watch(activeEntrepriseProvider).value;
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
                decoration: const InputDecoration(labelText: 'Nom*'),
                validator: (value) => value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(labelText: 'Adresse'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: activeEntreprise == null 
              ? null
              : () => _submitForm(ref, activeEntreprise.id),
          child: Text(isEditing ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }

  Future<void> _submitForm(WidgetRef ref, String entrepriseId) async {
    if (_formKey.currentState!.validate()) {
      try {
        final controller = ref.read(fournisseurControllerProvider.notifier);
        
        if (widget.fournisseur != null) {
          await controller.updateFournisseur(
            widget.fournisseur!.copyWith(
              nom: _nomController.text,
              telephone: _telephoneController.text.isEmpty ? null : _telephoneController.text,
              email: _emailController.text.isEmpty ? null : _emailController.text,
              adresse: _adresseController.text.isEmpty ? null : _adresseController.text,
            ),
          );
        } else {
          await controller.addFournisseur(
            nom: _nomController.text,
            entrepriseId: entrepriseId,
            telephone: _telephoneController.text.isEmpty ? null : _telephoneController.text,
            email: _emailController.text.isEmpty ? null : _emailController.text,
            adresse: _adresseController.text.isEmpty ? null : _adresseController.text,
          );
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString()}')),
          );
        }
      }
    }
  }
}