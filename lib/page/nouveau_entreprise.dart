import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/user_model.dart';
import 'package:project6/page/UserList.dart';
import 'package:project6/page/home_page.dart';


class NouveauEntreprise extends ConsumerStatefulWidget {
  const NouveauEntreprise({super.key});

  @override
  ConsumerState<NouveauEntreprise> createState() => _NouveauEntrepriseState();
}

class _NouveauEntrepriseState extends ConsumerState<NouveauEntreprise> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final entrepriseState = ref.watch(entrepriseControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Entreprise')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom de l\'entreprise'),
                validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(labelText: 'Adresse (optionnel)'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: entrepriseState.isLoading ? null : _submit,
                child: entrepriseState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
  if (_formKey.currentState!.validate()) {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    
    try {
      await ref.read(entrepriseControllerProvider.notifier).createEntreprise(
            nom: _nomController.text,
            adresse: _adresseController.text.isEmpty ? null : _adresseController.text,
            userId: user.id,
          );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserListScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    super.dispose();
  }
}