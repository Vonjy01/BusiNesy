import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/command_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/controller/fournisseur_controller.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/models/command_model.dart';
import 'package:project6/models/etat_commande.dart';
import 'package:project6/models/fournisseur_model.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/page/command/command_dialog.dart';

import 'package:project6/provider/etat_commande_provider.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';
import 'package:project6/widget/generic_tabview.dart';

class CommandList extends ConsumerStatefulWidget {
  const CommandList({Key? key}) : super(key: key);

  @override
  ConsumerState<CommandList> createState() => _CommandListState();
}

class _CommandListState extends ConsumerState<CommandList> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final activeEntrepriseState = ref.watch(activeEntrepriseProvider);
    final etatsCommandeState = ref.watch(etatCommandeProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Erreur: $error'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('Utilisateur non connecté')));

        return activeEntrepriseState.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Scaffold(body: Center(child: Text('Erreur: $error'))),
          data: (activeEntreprise) {
            if (activeEntreprise == null) {
              return Scaffold(
                body: Center(child: Text('Aucune entreprise active trouvée')),
              );
            }

            return etatsCommandeState.when(
              loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
              error: (error, stack) => Scaffold(body: Center(child: Text('Erreur: $error'))),
              data: (etats) {
                return Scaffold(
                  drawer: AppDrawer(user: user),
                  body: Column(
                    children: [
                  
                      Expanded(
                        child: GenericTabView(
                          headerTitle: 'Liste des commandes',
                          tabTitles: _buildTabTitles(etats),
                          tabViews: _buildTabViews(etats, user.id, activeEntreprise.id, ref),
                          tabBarOffsetY: -40,
                        ),
                      ),
                    ],
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => _showAddDialog(context, user.id, activeEntreprise.id, ref),
                    backgroundColor: background_theme,
                    child: Icon(Icons.add, color: color_white),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<String> _buildTabTitles(List<EtatCommande> etats) {
    return ['Toutes', ...etats.map((e) => e.libelle).toList()];
  }

  List<Widget> _buildTabViews(List<EtatCommande> etats, String userId, String entrepriseId, WidgetRef ref) {
    final allTab = _buildAllCommandesTab(userId, entrepriseId, ref);
    final etatTabs = etats.map((etat) => 
      _buildFilteredCommandesTab(userId, entrepriseId, etat.id, ref)
    ).toList();
    
    return [allTab, ...etatTabs];
  }

  Widget _buildAllCommandesTab(String userId, String entrepriseId, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final commandesState = ref.watch(commandeControllerProvider);
        final fournisseursState = ref.watch(fournisseurControllerProvider);
        final produitsState = ref.watch(produitControllerProvider);
        final etatsState = ref.watch(etatCommandeProvider);

        return commandesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
          data: (commandes) {
            return fournisseursState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
              data: (fournisseurs) {
                return produitsState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Erreur: $error')),
                  data: (produits) {
                    return etatsState.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(child: Text('Erreur: $error')),
                      data: (etats) {
                        return _buildCommandeList(
                          commandes, 
                          fournisseurs, 
                          produits,
                          etats,
                          userId,
                          entrepriseId,
                          ref,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilteredCommandesTab(String userId, String entrepriseId, int etatId, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final commandesState = ref.watch(commandeControllerProvider);
        final fournisseursState = ref.watch(fournisseurControllerProvider);
        final produitsState = ref.watch(produitControllerProvider);
        final etatsState = ref.watch(etatCommandeProvider);

        return commandesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
          data: (commandes) {
            final filteredCommandes = commandes.where((c) => c.etat == etatId).toList();
            
            return fournisseursState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
              data: (fournisseurs) {
                return produitsState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Erreur: $error')),
                  data: (produits) {
                    return etatsState.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erreur: $error')),
      data: (etats) {
        return _buildCommandeList(
          filteredCommandes, 
          fournisseurs, 
          produits,
          etats,
          userId,
          entrepriseId,
          ref,
        );
      },
    );
  },
);
},
);
},
);
},
);
}
}
Widget _buildCommandeList(
  List<Commande> commandes,
  List<Fournisseur> fournisseurs,
  List<Produit> produits,
  List<EtatCommande> etats,
  String userId,
  String entrepriseId,
  WidgetRef ref,
) {
  if (commandes.isEmpty) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Aucune commande trouvée', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Trier par date décroissante
  commandes.sort((a, b) => b.dateCommande.compareTo(a.dateCommande));

  // Grouper par date
  final Map<String, List<Commande>> groupedCommandes = {};
  for (var commande in commandes) {
    final dateKey = _formatDate(commande.dateCommande);
    if (!groupedCommandes.containsKey(dateKey)) {
      groupedCommandes[dateKey] = [];
    }
    groupedCommandes[dateKey]!.add(commande);
  }

  final dates = groupedCommandes.keys.toList(); // Liste des dates triées

  return RefreshIndicator(
    onRefresh: () async => ref.refresh(commandeControllerProvider),
    child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedCommandes.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final commandesForDate = groupedCommandes[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affiche la date
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                date,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            // Liste des commandes pour cette date
            ...commandesForDate.map((commande) {
              final fournisseur = fournisseurs.firstWhere(
                (f) => f.id == commande.fournisseurId,
                orElse: () => Fournisseur(
                  id: '',
                  nom: 'Inconnu',
                  entrepriseId: '',
                  createdAt: DateTime.now(),
                ),
              );

              final produit = produits.firstWhere(
                (p) => p.id == commande.produitId,
                orElse: () => Produit(
                  id: '',
                  nom: 'Inconnu',
                  stock: 0,
                  prixVente: 0,
                  prixAchat: 0,
                  defectueux: 0,
                  entrepriseId: '',
                  createdAt: DateTime.now(),
                  seuilAlerte: 5,
                ),
              );

              return GestureDetector(
                onTap: () => _showEditDialog(context, commande, userId, entrepriseId, ref),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: _buildEtatIcon(commande.etat),
                    title: Text(
                      '${produit.nom} (${commande.quantiteCommandee})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(fournisseur.nom),
                        if (commande.quantiteRecue != null)
                          Text('Reçue: ${commande.quantiteRecue}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDialog(context, commande, userId, entrepriseId, ref),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    ),
  );
}

Widget _buildEtatIcon(int etatId) {
  switch (etatId) {
    case 1:
      return const CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.access_time, color: Colors.white),
      );
    case 2:
      return const CircleAvatar(
        backgroundColor: Colors.green,
        child: Icon(Icons.check, color: Colors.white),
      );
    case 3:
      return const CircleAvatar(
        backgroundColor: Colors.orange,
        child: Icon(Icons.warning, color: Colors.white),
      );
    case 4:
      return const CircleAvatar(
        backgroundColor: Colors.red,
        child: Icon(Icons.close, color: Colors.white),
      );
    default:
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.help, color: Colors.white),
      );
  }
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

void _showAddDialog(BuildContext context, String userId, String entrepriseId, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => CommandeDialog(
      userId: userId,
      entrepriseId: entrepriseId,
    ),
  ).then((_) => ref.refresh(commandeControllerProvider));
}

void _showEditDialog(BuildContext context, Commande commande, String userId, String entrepriseId, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => CommandeDialog(
      commande: commande,
      userId: userId,
      entrepriseId: entrepriseId,
    ),
  ).then((_) => ref.refresh(commandeControllerProvider));
}

void _deleteCommande(BuildContext context, String id, WidgetRef ref) async {
  final controller = ref.read(commandeControllerProvider.notifier);
  try {
    await controller.deleteCommande(id);
    ref.refresh(commandeControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande supprimée avec succès')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la suppression: $e')),
    );
  }
}
