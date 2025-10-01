import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/controller/fournisseur_controller.dart';
import 'package:project6/models/fournisseur_model.dart';
import 'package:project6/page/fournisseur/edit_fournisseur_dialog.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';

class FournisseurList extends ConsumerStatefulWidget {
  const FournisseurList({super.key});

  @override
  ConsumerState<FournisseurList> createState() => _FournisseurListState();
}

class _FournisseurListState extends ConsumerState<FournisseurList> {
  String? _lastLoadedEntrepriseId;
  String? _currentSearchQuery;
  Timer? _searchTimer; 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFournisseursIfNeeded();
    });
  }

  void _loadFournisseursIfNeeded() {
    final activeEntreprise = ref.read(activeEntrepriseProvider).value;
    if (activeEntreprise != null &&
        _lastLoadedEntrepriseId != activeEntreprise.id) {
      _lastLoadedEntrepriseId = activeEntreprise.id;
      _currentSearchQuery = null; // Reset la recherche quand on change d'entreprise
      ref
          .read(fournisseurControllerProvider.notifier)
          .loadFournisseurs(activeEntreprise.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);  
    final activeEntreprise = ref.watch(activeEntrepriseProvider).value;
    final fournisseursAsync = ref.watch(fournisseurControllerProvider);

    if (activeEntreprise != null &&
        _lastLoadedEntrepriseId != activeEntreprise.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lastLoadedEntrepriseId = activeEntreprise.id;
        _currentSearchQuery = null; // Reset la recherche
        ref
            .read(fournisseurControllerProvider.notifier)
            .loadFournisseurs(activeEntreprise.id);
      });
    }

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Erreur: $error'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Utilisateur non connecté')),
          );
        }

        return Scaffold(
          drawer: AppDrawer(user: user),
          body: Column(
            children: [
              // ✅ Header avec bouton recherche et indicateur de recherche
              Header(
                title: 
                     'Fournisseurs',
                actions: [
                  if (activeEntreprise != null) ...[
                    if (_currentSearchQuery != null)
                      IconButton(
                        icon: const Icon(Icons.clear , color: color_white,),
                        onPressed: () {
                          setState(() => _currentSearchQuery = null);
                          ref
                              .read(fournisseurControllerProvider.notifier)
                              .loadFournisseurs(activeEntreprise.id, forceReload: true);
                        },
                        tooltip: 'Effacer la recherche',
                      ),
                    IconButton(
                      icon: const Icon(Icons.search, color: color_white,),
                      onPressed: () => _showSearchDialog(context, ref, activeEntreprise.id),
                    ),
                  ],
                ],
              ),

              if (activeEntreprise == null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Veuillez sélectionner une entreprise pour voir les fournisseurs',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),

              Expanded(
                child: activeEntreprise == null
                    ? const SizedBox()
                    : fournisseursAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Text(
                            'Erreur: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        data: (fournisseurs) {
                          if (fournisseurs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.group,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _currentSearchQuery != null
                                        ? 'Aucun fournisseur trouvé pour "${_currentSearchQuery!}"'
                                        : 'Aucun fournisseur enregistré',
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: background_theme,
                                    ),
                                    onPressed: () => _showAddDialog(
                                      context,
                                      activeEntreprise.id,
                                    ),
                                    child: const Text(
                                      'Ajouter un fournisseur',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: fournisseurs.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 20),
                            itemBuilder: (context, index) {
                              final fournisseur = fournisseurs[index];
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: background_theme
                                        .withOpacity(0.2),
                                    child: Text(
                                      fournisseur.nom[0].toUpperCase(),
                                      style: TextStyle(color: background_theme),
                                    ),
                                  ),
                                  title: Text(
                                    fournisseur.nom,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (fournisseur.telephone != null)
                                        Text(fournisseur.telephone!),
                                      if (fournisseur.email != null)
                                        Text(fournisseur.email!),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) =>
                                        _handlePopupSelection(
                                          value,
                                          context,
                                          fournisseur,
                                          activeEntreprise.id,
                                        ),
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
                                        if (fournisseur.telephone != null &&
                                            fournisseur.telephone!.isNotEmpty)
                                          const PopupMenuItem(
                                            value: 'appeler',
                                            child: Text('Appeler'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'supprimer',
                                          child: Text(
                                            'Supprimer',
                                            style: TextStyle(color: Colors.red),
                                          ),
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
          floatingActionButton: activeEntreprise == null
              ? null
              : FloatingActionButton(
                  onPressed: () => _showAddDialog(context, activeEntreprise.id),
                  backgroundColor: background_theme,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
        );
      },
    );
  }

  void _showSearchDialog(
    BuildContext context,
    WidgetRef ref,
    String entrepriseId,
  ) {
    final searchController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Rechercher un fournisseur"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Nom, téléphone, email, adresse...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (value) async {
                    if (value.isNotEmpty) {
                      setState(() => isLoading = true);
                      await ref
                          .read(fournisseurControllerProvider.notifier)
                          .searchFournisseursMulti(entrepriseId, value);
                      setState(() => isLoading = false);
                      if (context.mounted) {
                        setState(() => _currentSearchQuery = value);
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
                if (isLoading) 
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () {
                  setState(() => _currentSearchQuery = null);
                  ref
                      .read(fournisseurControllerProvider.notifier)
                      .loadFournisseurs(entrepriseId, forceReload: true);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Afficher tout"),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final query = searchController.text.trim();
                  setState(() => isLoading = true);
                  
                  if (query.isNotEmpty) {
                    await ref
                        .read(fournisseurControllerProvider.notifier)
                        .searchFournisseursMulti(entrepriseId, query);
                    setState(() => _currentSearchQuery = query);
                  } else {
                    await ref
                        .read(fournisseurControllerProvider.notifier)
                        .loadFournisseurs(entrepriseId);
                    setState(() => _currentSearchQuery = null);
                  }
                  
                  setState(() => isLoading = false);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Rechercher"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, String entrepriseId) {
    showDialog(
      context: context,
      builder: (context) => EditFournisseurDialog(entrepriseId: entrepriseId),
    ).then((_) {
      // Rafraîchir la liste après ajout
      if (_lastLoadedEntrepriseId != null) {
        ref
            .read(fournisseurControllerProvider.notifier)
            .loadFournisseurs(_lastLoadedEntrepriseId!, forceReload: true);
      }
    });
  }

  void _handlePopupSelection(
    String value,
    BuildContext context,
    Fournisseur fournisseur,
    String entrepriseId,
  ) {
    switch (value) {
      case 'detail':
        _showDetails(context, fournisseur);
        break;
      case 'modifier':
        showDialog(
          context: context,
          builder: (context) => EditFournisseurDialog(
            fournisseur: fournisseur,
            entrepriseId: entrepriseId,
          ),
        ).then((_) {
          // Rafraîchir la liste après modification
          if (_lastLoadedEntrepriseId != null) {
            ref
                .read(fournisseurControllerProvider.notifier)
                .loadFournisseurs(_lastLoadedEntrepriseId!, forceReload: true);
          }
        });
        break;
      case 'appeler':
        _callNumber(fournisseur.telephone);
        break;
      case 'supprimer':
        _confirmDelete(context, fournisseur, entrepriseId);
        break;
    }
  }

  void _showDetails(BuildContext context, Fournisseur fournisseur) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fournisseur.nom),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fournisseur.telephone != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 20),
                    const SizedBox(width: 8),
                    Text(fournisseur.telephone!),
                  ],
                ),
              ),
            if (fournisseur.email != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.email, size: 20),
                    const SizedBox(width: 8),
                    Text(fournisseur.email!),
                  ],
                ),
              ),
            if (fournisseur.adresse != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(fournisseur.adresse!)),
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

  /// 📞 Appeler un numéro
  Future<void> _callNumber(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Aucun numéro de téléphone disponible"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'ouvrir l'application téléphone"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Fournisseur fournisseur,
    String entrepriseId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${fournisseur.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteFournisseur(context, fournisseur, entrepriseId);
    }
  }

  Future<void> _deleteFournisseur(
    BuildContext context,
    Fournisseur fournisseur,
    String entrepriseId,
  ) async {
    try {
      final controller = ref.read(fournisseurControllerProvider.notifier);
      await controller.deleteFournisseur(fournisseur.id, entrepriseId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fournisseur.nom} a été supprimé'),
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
    @override
  void dispose() {
    _searchTimer?.cancel(); // Annuler le timer du widget
    super.dispose();
  }
}