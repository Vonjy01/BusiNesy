import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/page/home_page.dart';

class NouveauEntreprise extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _adresseController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                validator: (value) => value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
              ),
              TextFormField(
                controller: _motDePasseController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
              ),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(labelText: 'Adresse (optionnel)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    try {
                      await ref.read(entrepriseControllerProvider.notifier).createEntreprise(
                        nom: _nomController.text,
                        motDePasse: _motDePasseController.text,
                        adresse: _adresseController.text,
                      );
                      
                      // Redirection vers la page d'accueil
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: const Text('Créer l\'entreprise'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}