import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/client_controller.dart';
import 'package:project6/models/client_model.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';

class ClientPage extends ConsumerWidget {
  const ClientPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final clientsState = ref.watch(clientControllerProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Erreur: $error'))),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          drawer: AppDrawer(user: user),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.blue,
            onPressed: () => _showClientForm(context, ref, null, user.id),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              const Header(title: 'Gestion des Clients'),
              Expanded(
                child: clientsState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Erreur: $error')),
                  data: (clients) {
                    if (clients.isEmpty) {
                      return const Center(child: Text('Aucun client enregistré'));
                    }
                    return ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return ClientTile(
                          client: client,
                          onTap: () => _showClientForm(context, ref, client, user.id),
                        );
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
  }

  void _showClientForm(BuildContext context, WidgetRef ref, Client? client, String entrepriseId) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: client?.nom);
    final telephoneController = TextEditingController(text: client?.telephone);
    final emailController = TextEditingController(text: client?.email);
    final adresseController = TextEditingController(text: client?.adresse);
    final descriptionController = TextEditingController(text: client?.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(client == null ? 'Ajouter un client' : 'Modifier client'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomController,
                    decoration: const InputDecoration(labelText: 'Nom*'),
                    validator: (value) => value?.isEmpty ?? true ? 'Champ obligatoire' : null,
                  ),
                  TextFormField(
                    controller: telephoneController,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextFormField(
                    controller: adresseController,
                    decoration: const InputDecoration(labelText: 'Adresse'),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newClient = Client(
                    id: client?.id,
                    nom: nomController.text,
                    telephone: telephoneController.text,
                    email: emailController.text,
                    adresse: adresseController.text,
                    entrepriseId: entrepriseId,
                    description: descriptionController.text,
                    createdAt: client?.createdAt,
                    updatedAt: DateTime.now(),
                  );

                  if (client == null) {
                    ref.read(clientControllerProvider.notifier).addClient(newClient);
                  } else {
                    ref.read(clientControllerProvider.notifier).updateClient(newClient);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(client == null ? 'Ajouter' : 'Mettre à jour', 
                style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class ClientTile extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;

  const ClientTile({super.key, required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(client.nom[0].toUpperCase()),
        ),
        title: Text(client.nom),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.telephone != null) Text('Tél: ${client.telephone}'),
            if (client.email != null) Text('Email: ${client.email}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onTap,
        ),
      ),
    );
  }
}