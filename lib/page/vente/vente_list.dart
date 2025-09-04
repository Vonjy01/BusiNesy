import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/vente_controller.dart';
import 'package:project6/controller/client_controller.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/vente_model.dart';
import 'package:project6/models/client_model.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/models/etat_commande.dart';
import 'package:project6/page/vente/vente_details.dart';
import 'package:project6/page/vente/vente_dialog.dart';
import 'package:project6/provider/etat_commande_provider.dart';
import 'package:project6/widget/app_drawer.dart';
import 'package:project6/widget/generic_tabview.dart';
import 'package:project6/utils/constant.dart';

class VenteList extends ConsumerStatefulWidget {
  const VenteList({Key? key}) : super(key: key);

  @override
  ConsumerState<VenteList> createState() => _VenteListState();
}

class _VenteListState extends ConsumerState<VenteList> {
  final Map<String, List<Vente>> _groupedVentes = {};

  Map<String, List<Vente>> _groupVentesByClientAndDate(List<Vente> ventes) {
    final Map<String, List<Vente>> grouped = {};
    
    for (final vente in ventes) {
      final key = '${vente.clientId}-${vente.dateVente.year}-${vente.dateVente.month}-${vente.dateVente.day}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(vente);
    }
    
    return grouped;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

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
                          headerTitle: 'Liste des ventes',
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
    final allTab = _buildAllVentesTab(userId, entrepriseId, ref);
    final etatTabs = etats.map((etat) => 
      _buildFilteredVentesTab(userId, entrepriseId, etat.id, ref)
    ).toList();
    
    return [allTab, ...etatTabs];
  }

  Widget _buildAllVentesTab(String userId, String entrepriseId, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final ventesState = ref.watch(venteControllerProvider);
        final clientsState = ref.watch(clientControllerProvider);
        final produitsState = ref.watch(produitControllerProvider);

        return ventesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
          data: (ventes) {
            _groupedVentes.clear();
            _groupedVentes.addAll(_groupVentesByClientAndDate(ventes));
            
            return clientsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
              data: (clients) {
                return produitsState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Erreur: $error')),
                  data: (produits) {
                    return _buildGroupedVenteList(_groupedVentes, clients, produits, userId, entrepriseId, ref);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilteredVentesTab(String userId, String entrepriseId, int etatId, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final ventesState = ref.watch(venteControllerProvider);
        final clientsState = ref.watch(clientControllerProvider);
        final produitsState = ref.watch(produitControllerProvider);

        return ventesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
          data: (ventes) {
            final filteredVentes = ventes.where((v) => v.etat == etatId).toList();
            final groupedFilteredVentes = _groupVentesByClientAndDate(filteredVentes);
            
            return clientsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
              data: (clients) {
                return produitsState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Erreur: $error')),
                  data: (produits) {
                    return _buildGroupedVenteList(groupedFilteredVentes, clients, produits, userId, entrepriseId, ref);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGroupedVenteList(
    Map<String, List<Vente>> groupedVentes,
    List<Client> clients,
    List<Produit> produits,
    String userId,
    String entrepriseId,
    WidgetRef ref,
  ) {
    if (groupedVentes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune vente trouvée', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(venteControllerProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedVentes.length,
        itemBuilder: (context, index) {
          final key = groupedVentes.keys.elementAt(index);
          final ventes = groupedVentes[key]!;
          final firstVente = ventes.first;
          
          final client = clients.firstWhere(
            (c) => c.id == firstVente.clientId,
            orElse: () => Client(
              id: '',
              nom: 'Aucun client',
              entrepriseId: '',
              createdAt: DateTime.now(),
              telephone: null,
              email: null,
              adresse: null,
              description: null,
              updatedAt: null,
            ),
          );

          final total = ventes.fold(0.0, (sum, v) => sum + v.prixTotal);
          final produitCount = ventes.length;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: _buildEtatIcon(firstVente.etat),
              title: Text(
                client.nom,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('$produitCount produit(s)'),
                  Text('Total: ${total.toStringAsFixed(2)} $devise'),
                  Text('Date: ${_formatDate(firstVente.dateVente)}'),
                  Text('État: ${_getEtatLibelle(firstVente.etat)}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditDialog(context, ventes, userId, entrepriseId, ref),
                    tooltip: 'Modifier la commande',
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('Voir détails'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        _showDetails(context, ventes, client, produits);
                      } else if (value == 'delete') {
                        _deleteVentes(context, ventes, ref, userId);
                      }
                    },
                  ),
                ],
              ),
              onTap: () => _showDetails(context, ventes, client, produits),
            ),
          );
        },
      ),
    );
  }

  String _getEtatLibelle(int etatId) {
    switch (etatId) {
      case 1: return 'En attente';
      case 2: return 'Validé';
      case 3: return 'Incomplet';
      case 4: return 'Annulé';
      default: return 'Inconnu';
    }
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

  void _showAddDialog(BuildContext context, String userId, String entrepriseId, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => VenteDialog(
        userId: userId,
        entrepriseId: entrepriseId,
      ),
    ).then((_) {
      if (mounted) {
        ref.refresh(venteControllerProvider);
      }
    });
  }

  void _showEditDialog(BuildContext context, List<Vente> ventes, String userId, String entrepriseId, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => VenteDialog(
        vente: ventes.first,
        userId: userId,
        entrepriseId: entrepriseId,
      ),
    ).then((_) {
      if (mounted) {
        ref.refresh(venteControllerProvider);
      }
    });
  }

  void _showDetails(BuildContext context, List<Vente> ventes, Client client, List<Produit> produits) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenteGroupDetailPage(
          ventes: ventes,
          client: client,
          produits: produits,
        ),
      ),
    );
  }

  void _deleteVentes(BuildContext context, List<Vente> ventes, WidgetRef ref, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette commande de ${ventes.length} produit(s) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final venteController = ref.read(venteControllerProvider.notifier);
      try {
        for (final vente in ventes) {
          await venteController.deleteVente(vente.id, userId);
        }
        if (mounted) {
          ref.refresh(venteControllerProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Commande supprimée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }
}