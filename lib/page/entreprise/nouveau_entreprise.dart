import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/page/entreprise/entreprise_selection.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/logo.dart';

class NouveauEntreprise extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _adresseController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return  Container(
        decoration: const BoxDecoration(gradient: headerGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icone
                     Logo(size: 80,),
                      const SizedBox(height: 20),
                      const Text(
                        'Créez votre nouvelle entreprise',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),

                      // Champ nom entreprise
                      TextFormField(
                        controller: _nomController,
                        decoration: InputDecoration(
                          labelText: 'Nom de l\'entreprise',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Ce champ est obligatoire'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Champ mot de passe
                      TextFormField(
                        controller: _motDePasseController,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              // Utiliser setState si vous convertissez en StatefulWidget
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Ce champ est obligatoire'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Champ adresse
                      TextFormField(
                        controller: _adresseController,
                        decoration: InputDecoration(
                          labelText: 'Adresse (optionnel)',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),

                      // Bouton de création
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: background_theme,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              try {
                                await ref
                                    .read(entrepriseControllerProvider.notifier)
                                    .createEntreprise(
                                      nom: _nomController.text,
                                      motDePasse: _motDePasseController.text,
                                      adresse: _adresseController.text,
                                    );

                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const EntrepriseSelectionPage(),
                                  ),
                                  (route) => false,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Créer l\'entreprise',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Bouton annuler
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context)=> EntrepriseSelectionPage())
                        ),
                        child: const Text(
                          'Vous avez déjà une entreprise?',
                          style: TextStyle(
                            color: background_theme,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      
    );
  }
}
