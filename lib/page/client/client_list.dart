// page/client/client_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/controller/client_controller.dart';
import 'package:project6/models/client_model.dart';
import 'package:project6/page/client/client_dialog.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';

class ClientList extends ConsumerStatefulWidget {
  const ClientList({super.key});

  @override
  ConsumerState<ClientList> createState() => _ClientListState();
}

class _ClientListState extends ConsumerState<ClientList> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final activeEntreprise = ref.watch(activeEntrepriseProvider).value;
    final clientsAsync = ref.watch(clientControllerProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Erreur: $error'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Utilisateur non connecté')));
        }

        return Scaffold(
          drawer: AppDrawer(user: user),
          body: Column(
            children: [
              const Header(title: 'Clients'),
              Expanded(
                child: clientsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Erreur: $error', style: const TextStyle(color: Colors.red)),
                  ),
                  data: (clients) {
                    if (clients.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people, size: 50, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('Aucun client enregistré'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: background_theme,
                              ),
                              onPressed: activeEntreprise == null
                                  ? null
                                  : () => _showAddDialog(context),
                              child: const Text('Ajouter un client', 
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: clients.length,
                      separatorBuilder: (context, index) => const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                            leading: CircleAvatar(
                              backgroundColor: background_theme.withOpacity(0.2),
                              child: Text(
                                client.nom[0].toUpperCase(),
                                style: TextStyle(color: background_theme),
                              ),
                            ),
                            title: Text(
                              client.nom,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (client.telephone != null)
                                  Text(client.telephone!),
                                if (client.email != null)
                                  Text(client.email!),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) => _handlePopupSelection(
                                value, context, client),
                              itemBuilder: (BuildContext context) {
                                return [
                                  const PopupMenuItem(
                                    value: 'detail',
                                    child: Text('Détails'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'modifier',
                                    child: Text('Modifier'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'appeler',
                                    child: Text('Appeler'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'supprimer',
                                    child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                                  ),
                                ];
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: activeEntreprise == null ? null : () => _showAddDialog(context),
            backgroundColor: background_theme,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EditClientDialog(),
    );
  }

  void _handlePopupSelection(String value, BuildContext context, Client client) {
    switch (value) {
      case 'detail':
        _showDetails(context, client);
        break;
      case 'modifier':
        showDialog(
          context: context,
          builder: (context) => EditClientDialog(client: client),
        );
        break;
      case 'appeler':
        _callNumber(client.telephone);
        break;
      case 'supprimer':
        _confirmDelete(context, client);
        break;
    }
  }

  void _showDetails(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${client.nom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.telephone != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 20),
                    const SizedBox(width: 8),
                    Text(client.telephone!),
                  ],
                ),
              ),
            if (client.email != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [ 
                    const Icon(Icons.email, size: 20),
                    const SizedBox(width: 8),
                    Text(client.email!),
                  ],
                ),
              ),
            if (client.adresse != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(client.adresse!)),
                  ],
                ),
              ),
            if (client.description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(client.description!)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _callNumber(String? phoneNumber) async {
    if (phoneNumber == null) return;
    // Implémentez la logique d'appel ici
  }

  Future<void> _confirmDelete(BuildContext context, Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${client.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await _deleteClient(context, client);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClient(BuildContext context, Client client) async {
    try {
      final controller = ref.read(clientControllerProvider.notifier);
      await controller.deleteClient(client.id, client.entrepriseId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${client.nom} a été supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}