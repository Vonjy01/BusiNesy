import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/page/entreprise/entreprise_password.dart';
import 'package:project6/page/entreprise/nouveau_entreprise.dart';
import 'package:project6/utils/constant.dart';

class EntrepriseSelectionPage extends ConsumerWidget {
  const EntrepriseSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entreprisesAsync = ref.watch(entrepriseControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Sélection entreprise'),
        backgroundColor: Colors.white,
        foregroundColor: background_theme,
        elevation: 2,
        centerTitle: true,
      ),
      body: entreprisesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(background_theme),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Erreur: $err',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.refresh(entrepriseControllerProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (entreprises) {
          final user = authState.value;
          final userEntreprises = user != null 
              ? entreprises.where((e) => e.userId == user.id).toList() 
              : [];

          if (userEntreprises.isEmpty) {
            return _buildNoEnterpriseUI(context);
          }

          return _buildEnterpriseList(context, userEntreprises);
        },
      ),
    );
  }

  Widget _buildNoEnterpriseUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: background_theme,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business,
                size: 60,
                color: color_white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune entreprise',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: background_theme,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vous n\'avez pas encore créé d\'entreprise.\nCommencez par créer votre première entreprise.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_business),
                label: const Text(
                  'Créer une entreprise',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: background_theme,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) =>  NouveauEntreprise()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterpriseList(BuildContext context, List<dynamic> userEntreprises) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Column(
            children: [
              const Icon(
                Icons.business_center,
                size: 48,
                color: background_theme,
              ),
              const SizedBox(height: 16),
              const Text(
                'Vos entreprises',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: background_theme,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez une entreprise pour continuer',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Liste des entreprises
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: userEntreprises.length,
            itemBuilder: (context, index) {
              final e = userEntreprises[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: background_theme,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: color_white,
                    ),
                  ),
                  title: Text(
                    e.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    e.adresse ?? "Aucune adresse",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: background_theme,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: color_white,
                      size: 20,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EntreprisePasswordPage(
                          entrepriseId: e.id,
                          entrepriseNom: e.nom,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Bouton nouvelle entreprise
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle entreprise'),
              style: OutlinedButton.styleFrom(
                foregroundColor: background_theme,
                side: const BorderSide(color: background_theme),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) =>  NouveauEntreprise()),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}