import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/vente_controller.dart';
import 'package:project6/controller/client_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/vente_model.dart';
import 'package:project6/models/client_model.dart';
import 'package:project6/page/vente/vente_details.dart';
import 'package:project6/widget/app_drawer.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/utils/constant.dart';

class VenteList extends ConsumerStatefulWidget {
  const VenteList({Key? key}) : super(key: key);

  @override
  ConsumerState<VenteList> createState() => _VenteListState();
}

class _VenteListState extends ConsumerState<VenteList> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final activeEntrepriseState = ref.watch(activeEntrepriseProvider);
    final ventesState = ref.watch(venteControllerProvider);
    final clientsState = ref.watch(clientControllerProvider);

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

            return Scaffold(
              drawer: AppDrawer(user: user),
              body: Column(
                children: [
                  Header(
                    title: 'Liste des ventes',
                    showDrawerIcon: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => _createNewVente(context, user.id, activeEntreprise.id, ref),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ventesState.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(child: Text('Erreur: $error')),
                      data: (ventes) {
                        return clientsState.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Center(child: Text('Erreur: $error')),
                          data: (clients) {
                            return _buildVenteList(ventes, clients, user.id, activeEntreprise.id, ref);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVenteList(List<Vente> ventes, List<Client> clients, String userId, String entrepriseId, WidgetRef ref) {
    if (ventes.isEmpty) {
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

    // Grouper les ventes par client ET date pour créer des commandes distinctes
    final Map<String, List<Vente>> ventesGrouped = _groupVentesByClientAndDate(ventes);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(venteControllerProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ventesGrouped.length,
        itemBuilder: (context, index) {
          final groupKey = ventesGrouped.keys.elementAt(index);
          final clientVentes = ventesGrouped[groupKey]!;
          
          // Extraire le clientId du groupKey (format: clientId-date)
          final clientId = groupKey.split('-')[0];
          final client = clients.firstWhere(
            (c) => c.id == clientId, 
            orElse: () => Client(
              id: '', 
              nom: 'Client inconnu', 
              entrepriseId: '', 
              createdAt: DateTime.now(),
              telephone: '',
              email: '',
              adresse: '',
              description: ''
            )
          );
          
          // Calculer le total pour cette commande
          final total = clientVentes.fold(0.0, (sum, v) => sum + v.prixTotal);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: background_theme,
                child: Text(
                  client.nom.isNotEmpty ? client.nom[0] : '?', 
                  style: TextStyle(color: color_white)
                ),
              ),
              title: Text(
                client.nom,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('${clientVentes.length} produit(s)'),
                  Text('Total: ${total.toStringAsFixed(2)} $devise'),
                  Text('Date: ${_formatDate(clientVentes.first.dateVente)}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _showVenteDetails(context, clientVentes, client),
              ),
              onTap: () => _showVenteDetails(context, clientVentes, client),
            ),
          );
        },
      ),
    );
  }

  // Méthode pour grouper les ventes par client ET date
  Map<String, List<Vente>> _groupVentesByClientAndDate(List<Vente> ventes) {
    final Map<String, List<Vente>> grouped = {};
    
    for (final vente in ventes) {
      if (vente.clientId != null) {
        // Créer une clé unique avec clientId + date (sans l'heure)
        final dateKey = '${vente.dateVente.year}-${vente.dateVente.month}-${vente.dateVente.day}';
        final key = '${vente.clientId}-$dateKey';
        
        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(vente);
      }
    }
    
    return grouped;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _createNewVente(BuildContext context, String userId, String entrepriseId, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenteDetailPage(
          client: null, // Nouvelle vente
          userId: userId,
          entrepriseId: entrepriseId,
        ),
      ),
    ).then((_) {
      if (mounted) {
        ref.refresh(venteControllerProvider);
      }
    });
  }

  void _showVenteDetails(BuildContext context, List<Vente> ventes, Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenteDetailPage(
          ventes: ventes,
          client: client,
          userId: ventes.first.userId,
          entrepriseId: ventes.first.entrepriseId,
        ),
      ),
    );
  }
}