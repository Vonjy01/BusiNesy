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
import 'package:intl/intl.dart';

class VenteList extends ConsumerStatefulWidget {
  const VenteList({Key? key}) : super(key: key);

  @override
  ConsumerState<VenteList> createState() => _VenteListState();
}

class _VenteListState extends ConsumerState<VenteList> {
  String? _lastLoadedEntrepriseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataIfNeeded();
    });
  }

  void _loadDataIfNeeded() {
    final activeEntreprise = ref.read(activeEntrepriseProvider).value;
    if (activeEntreprise != null && _lastLoadedEntrepriseId != activeEntreprise.id) {
      _lastLoadedEntrepriseId = activeEntreprise.id;
      ref.read(venteControllerProvider.notifier).loadVentes(activeEntreprise.id);
      ref.read(clientControllerProvider.notifier).loadClients(activeEntreprise.id);
    }
  }

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
                            return _buildVenteList(ventes, clients, ref);
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

  Widget _buildVenteList(List<Vente> ventes, List<Client> clients, WidgetRef ref) {
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

    final groupedBySession = ref.read(venteControllerProvider.notifier).groupVentesBySession(ventes);
    final sessionIds = groupedBySession.keys.toList();

    return RefreshIndicator(
      onRefresh: () async {
        final activeEntreprise = ref.read(activeEntrepriseProvider).value;
        if (activeEntreprise != null) {
          await ref.read(venteControllerProvider.notifier).loadVentes(activeEntreprise.id);
          await ref.read(clientControllerProvider.notifier).loadClients(activeEntreprise.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessionIds.length,
        itemBuilder: (context, index) {
          final sessionId = sessionIds[index];
          final sessionVentes = groupedBySession[sessionId]!;
          final firstVente = sessionVentes.first;
          
          final client = clients.firstWhere(
            (c) => c.id == firstVente.clientId,
            orElse: () => Client(
              id: '',
              nom: 'Client inconnu',
              entrepriseId: '',
              createdAt: DateTime.now(),
            ),
          );

          if (client.id.isEmpty) {
            return const SizedBox.shrink();
          }
          
          final total = sessionVentes.fold(0.0, (sum, v) => sum + v.prixTotal);
          final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
          
          // Dans _buildVenteList() de VenteList
return Card(
  margin: const EdgeInsets.only(bottom: 16),
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: ListTile(
    contentPadding: const EdgeInsets.all(16),
    leading: CircleAvatar(
      backgroundColor: background_theme,
      child: Text(
        client.nom[0], 
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
        Text('${sessionVentes.length} produit(s)'),
        Text('Date: ${dateFormat.format(firstVente.dateVente)}'),
        Text('Total: ${total.toStringAsFixed(2)} $devise'),
        // AFFICHEZ L'ID DE SESSION DANS LA LISTE
        Text(
          sessionId.isNotEmpty 
            ? 'Session: ${sessionId.length > 8 ? sessionId.substring(0, 8) + '...' : sessionId}'
            : 'Session: Non défini',
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
        ),
      ],
    ),
    trailing: IconButton(
      icon: const Icon(Icons.arrow_forward),
      onPressed: () => _showSessionDetails(context, sessionVentes, client, sessionId),
    ),
    onTap: () => _showSessionDetails(context, sessionVentes, client, sessionId),
  ),
);
        },
      ),
    );
  }
void _createNewVente(BuildContext context, String userId, String entrepriseId, WidgetRef ref) {
  final venteController = ref.read(venteControllerProvider.notifier);
  final newSessionId = venteController.generateNewSessionId();
  
  print('Création nouvelle vente avec session: $newSessionId');
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VenteDetailPage(
        ventes: null,
        client: null,
        userId: userId,
        entrepriseId: entrepriseId,
        sessionId: newSessionId,
      ),
    ),
  ).then((success) {
    if (success == true && mounted) {
      final activeEntreprise = ref.read(activeEntrepriseProvider).value;
      if (activeEntreprise != null) {
        print('Rechargement des ventes après sauvegarde');
        ref.read(venteControllerProvider.notifier).loadVentes(activeEntreprise.id);
      }
    }
  });
}
  void _showSessionDetails(BuildContext context, List<Vente> ventes, Client client, String sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenteDetailPage(
          ventes: ventes,
          client: client,
          userId: ventes.first.userId,
          entrepriseId: ventes.first.entrepriseId,
          sessionId: sessionId,
        ),
      ),
    );
  }
}