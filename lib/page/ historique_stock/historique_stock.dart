import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/historique_stock_controller.dart';
import 'package:project6/provider/entreprise_provider.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';

class HistoriqueStockList extends ConsumerWidget {
  const HistoriqueStockList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final activeEntreprise = ref.watch(activeEntrepriseProvider).value;

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Erreur: $error'))),
      data: (user) {
        if (user == null || activeEntreprise == null) {
          return const Scaffold(body: Center(child: Text('Accès non autorisé')));
        }

        final historique = ref.watch(historiqueStockProvider(activeEntreprise.id));

        return Scaffold(
          drawer: AppDrawer(user: user),
          body: Column(
            children: [
              const Header(title: 'Historique des stocks'),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    return ref.refresh(historiqueStockProvider(activeEntreprise.id).future);
                  },
                  child: historique.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Erreur: $error')),
                    data: (mouvements) {
                      if (mouvements.isEmpty) {
                        return const Center(
                          child: Text('Aucun mouvement enregistré'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: mouvements.length,
                        itemBuilder: (context, index) {
                          final mouvement = mouvements[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        mouvement['produit_nom'] ?? 'Produit inconnu',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        mouvement['created_at'].substring(0, 10),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Quantité: ${mouvement['quantite']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        mouvement['user_nom'] ?? 'Utilisateur inconnu',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (mouvement['defectueux'] != null && mouvement['defectueux'] > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Défectueux: ${mouvement['defectueux']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  if (mouvement['note'] != null && mouvement['note'].isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Note: ${mouvement['note']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}