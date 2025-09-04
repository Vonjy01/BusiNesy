// page/client/edit_client_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/controller/client_controller.dart';
import 'package:project6/models/client_model.dart';

class EditClientDialog extends ConsumerStatefulWidget {
  final Client? client;

  const EditClientDialog({
    super.key,
    this.client,
  });

  @override
  ConsumerState<EditClientDialog> createState() => _EditClientDialogState();
}

class _EditClientDialogState extends ConsumerState<EditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  late TextEditingController _adresseController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.client?.nom ?? '');
    _telephoneController = TextEditingController(text: widget.client?.telephone ?? '');
    _emailController = TextEditingController(text: widget.client?.email ?? '');
    _adresseController = TextEditingController(text: widget.client?.adresse ?? '');
    _descriptionController = TextEditingController(text: widget.client?.description ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEntreprise = ref.watch(activeEntrepriseProvider).value;
    final isEditing = widget.client != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier Client' : 'Nouveau Client'),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
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
        final controller = ref.read(clientControllerProvider.notifier);
        
        if (widget.client != null) {
          await controller.updateClient(
            widget.client!.copyWith(
              nom: _nomController.text,
              telephone: _telephoneController.text.isEmpty ? null : _telephoneController.text,
              email: _emailController.text.isEmpty ? null : _emailController.text,
              adresse: _adresseController.text.isEmpty ? null : _adresseController.text,
              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            ),
          );
        } else {
          await controller.addClient(
            nom: _nomController.text,
            entrepriseId: entrepriseId,
            telephone: _telephoneController.text.isEmpty ? null : _telephoneController.text,
            email: _emailController.text.isEmpty ? null : _emailController.text,
            adresse: _adresseController.text.isEmpty ? null : _adresseController.text,
            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
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