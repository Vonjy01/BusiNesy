import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/categorie_produit_model.dart';
import 'package:project6/page/cat_prod.dart/cat_prod_dialog.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';

class CategorieProduitList extends ConsumerStatefulWidget {
  const CategorieProduitList({super.key});

  @override
  ConsumerState<CategorieProduitList> createState() => _CategorieProduitListState();
}

class _CategorieProduitListState extends ConsumerState<CategorieProduitList> {
  String? _lastLoadedEntrepriseId;

  @override
  void initState() {
    super.initState();
    // Charger les catégories après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesIfNeeded();
    });
  }

  void _loadCategoriesIfNeeded() {
    final activeEntreprise = ref.read(activeEntrepriseProvider).value;
    if (activeEntreprise != null && _lastLoadedEntrepriseId != activeEntreprise.id) {
      _lastLoadedEntrepriseId = activeEntreprise.id;
      ref.read(categorieProduitControllerProvider.notifier).loadCategories(activeEntreprise.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final activeEntreprise = ref.watch(activeEntrepriseProvider).value;
    final categoriesAsync = ref.watch(categorieProduitControllerProvider);

    // Recharger seulement si l'entreprise active change
    if (activeEntreprise != null && _lastLoadedEntrepriseId != activeEntreprise.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lastLoadedEntrepriseId = activeEntreprise.id;
        ref.read(categorieProduitControllerProvider.notifier).loadCategories(activeEntreprise.id);
      });
    }

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
              const Header(title: 'Catégories Produits'),
              if (activeEntreprise == null) 
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Veuillez sélectionner une entreprise pour voir les catégories',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: activeEntreprise == null 
                  ? const SizedBox()
                  : categoriesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Erreur: $error', style: const TextStyle(color: Colors.red)),
                      ),
                      data: (categories) {
                        if (categories.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.category, size: 50, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text('Aucune catégorie enregistrée'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: background_theme,
                                  ),
                                  onPressed: () => _showAddDialog(context, activeEntreprise.id),
                                  child: const Text('Ajouter une catégorie', 
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: categories.length,
                          separatorBuilder: (context, index) => const Divider(height: 20),
                          itemBuilder: (context, index) {
                            final categorie = categories[index];
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
                                  child: Icon(Icons.category, color: background_theme),
                                ),
                                title: Text(
                                  categorie.libelle,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) => _handlePopupSelection(
                                    value, context, categorie, activeEntreprise.id),
                                  itemBuilder: (BuildContext context) {
                                    return [
                                      const PopupMenuItem(
                                        value: 'modifier',
                                        child: Text('Modifier'),
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

  void _showAddDialog(BuildContext context, String entrepriseId) {
    showDialog(
      context: context,
      builder: (context) => CategorieDialog(entrepriseId: entrepriseId),
    );
  }

  void _handlePopupSelection(String value, BuildContext context, CategorieProduit categorie, String entrepriseId) {
    switch (value) {
      case 'modifier':
        showDialog(
          context: context,
          builder: (context) => CategorieDialog(
            categorie: categorie, 
            entrepriseId: entrepriseId
          ),
        );
        break;
      case 'supprimer':
        _confirmDelete(context, categorie, entrepriseId);
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context, CategorieProduit categorie, String entrepriseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer définitivement "${categorie.libelle}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await _deleteCategorie(context, categorie, entrepriseId);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategorie(BuildContext context, CategorieProduit categorie, String entrepriseId) async {
    try {
      final controller = ref.read(categorieProduitControllerProvider.notifier);
      await controller.deleteCategorie(categorie.id!, entrepriseId);
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${categorie.libelle}" supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}