import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/models/categorie_produit_model.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/models/user_model.dart';
import 'package:project6/page/produit/produit_dialog.dart';
import 'package:project6/page/produit/produit_search.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';
import 'package:project6/widget/produit_widget.dart';

class ProduitList extends ConsumerStatefulWidget {
  const ProduitList({Key? key}) : super(key: key);

  @override
  ConsumerState<ProduitList> createState() => _ProduitListState();
}

class _ProduitListState extends ConsumerState<ProduitList> {
  String _searchName = '';
  String _searchCategory = 'Toutes';
  List<String> _categories = ['Toutes'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(produitControllerProvider.notifier).loadProduits();
      // Enlever .loadCategories() si ça n'existe pas
    });
    _loadCategories();
  }

Future<void> _loadCategories() async {
  final categoriesState = ref.read(categorieProduitControllerProvider);
  
  print('État des catégories: $categoriesState'); // Debug
  
  categoriesState.when(
    data: (categories) {
      print('Nombre de catégories: ${categories.length}'); // Debug
      setState(() {
        _categories = ['Toutes', ...categories.map((c) => c.libelle).toList()];
        print('Catégories finales: $_categories'); // Debug
      });
    },
    error: (error, stack) {
      print('Erreur chargement catégories: $error');
    },
    loading: () {
      print('Chargement des catégories en cours...'); // Debug
    },
  );
}

void _showSearchDialog() async {
  // Attendre que les catégories soient chargées
  final categoriesState = ref.read(categorieProduitControllerProvider);
  
  categoriesState.when(
    data: (categories) {
      // Créer la liste des noms de catégories
      final categoryNames = ['Toutes', ...categories.map((c) => c.libelle).toList()];
      
      showDialog(
        context: context,
        builder: (context) => ProduitSearchDialog(
          produits: ref.read(produitControllerProvider).value ?? [],
          categories: categoryNames,
          onSearch: (name, category) {
            setState(() {
              _searchName = name;
              _searchCategory = category;
            });
          },
        ),
      );
    },
    error: (error, stack) {
      // Afficher une erreur si le chargement échoue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement catégories: $error')),
      );
    },
    loading: () {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des catégories...'),
            ],
          ),
        ),
      );
    },
  );
}

  List<Produit> _filterProduits(List<Produit> produits, List<CategorieProduit> categories) {
    return produits.where((produit) {
      final matchesName = _searchName.isEmpty ||
          produit.nom.toLowerCase().contains(_searchName.toLowerCase());
      
      final matchesCategory = _searchCategory.isEmpty ||
          _searchCategory == 'Toutes' ||
          _getCategorieLibelle(produit.categorieId, categories) == _searchCategory;
      
      return matchesName && matchesCategory;
    }).toList();
  }

  String _getCategorieLibelle(int? categorieId, List<CategorieProduit> categories) {
    if (categorieId == null) return 'Inconnu';
    
    final categorie = categories.firstWhere(
      (c) => c.id == categorieId,
      orElse: () => CategorieProduit(id: 0, libelle: 'Inconnu', entrepriseId: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
    return categorie.libelle;
  }

  @override
  Widget build(BuildContext context) {
    final produitsState = ref.watch(produitControllerProvider);
    final categoriesState = ref.watch(categorieProduitControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => _buildLoadingScreen(),
      error: (error, stack) => _buildErrorScreen(error),
      data: (user) {
        if (user == null) return _buildNoUserScreen();

        return categoriesState.when(
          loading: () => _buildScaffold(
            context,
            user.id,
            user: user,
            tabViews: [
              _buildLoadingTab(),
              _buildLoadingTab(),
              _buildLoadingTab(),
              _buildLoadingTab(),
            ],
          ),
          error: (error, stack) => _buildScaffold(
            context,
            user.id,
            user: user,
            tabViews: [
              _buildErrorTab(error),
              _buildErrorTab(error),
              _buildErrorTab(error),
              _buildErrorTab(error),
            ],
          ),
          data: (categories) {
            return produitsState.when(
              loading: () => _buildScaffold(
                context,
                user.id,
                user: user,
                tabViews: [
                  _buildLoadingTab(),
                  _buildLoadingTab(),
                  _buildLoadingTab(),
                  _buildLoadingTab(),
                ],
              ),
              error: (error, stack) => _buildScaffold(
                context,
                user.id,
                user: user,
                tabViews: [
                  _buildErrorTab(error),
                  _buildErrorTab(error),
                  _buildErrorTab(error),
                  _buildErrorTab(error),
                ],
              ),
              data: (produits) {
                final filteredProduits = _filterProduits(produits, categories);
                
                final tousProduits = filteredProduits;
                final stockBas = filteredProduits.where((p) => 
                  p.stockDisponible > 0 && p.stockDisponible <= p.seuilAlerte).toList();
                final epuise = filteredProduits.where((p) => p.stockDisponible <= 0).toList();
                final defectueux = filteredProduits.where((p) => p.defectueux > 0).toList();

                return _buildScaffold(
                  context,
                  user.id,
                  user: user,
                  tabViews: [
                    _buildProduitList(tousProduits, categories, false, false, user.id),
                    _buildProduitList(stockBas, categories, true, true, user.id),
                    _buildProduitList(epuise, categories, false, false, user.id),
                    _buildDefectiveList(defectueux, categories, user.id),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );

  Widget _buildErrorScreen(dynamic error) => Scaffold(
        body: Center(child: Text('Erreur: $error')),
      );

  Widget _buildNoUserScreen() => const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );

  Widget _buildScaffold(
    BuildContext context,
    String userId, {
    required User user,
    required List<Widget> tabViews,
  }) {
    return Scaffold(
      drawer: AppDrawer(user: user),
      body: Column(
        children: [
          Header(
            title: 'Gestion des produits',
            showDrawerIcon: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _showSearchDialog,
                tooltip: 'Rechercher',
              ),
            ],
          ),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TabBar(
                        labelColor: background_theme,
                        unselectedLabelColor: Colors.grey,
                        indicator: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: background_theme, width: 5),
                          ),
                        ),
                        dividerColor: Colors.transparent, 
                        tabs: const [
                          Tab(text: 'Tous'),
                          Tab(text: 'Bas'),
                          Tab(text: 'Épuisé'),
                          Tab(text: 'Déchet'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(children: tabViews),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, userId),
        backgroundColor: background_theme,
        child: Icon(Icons.add, color: color_white),
      ),
    );
  }

  Widget _buildLoadingTab() => const Center(child: CircularProgressIndicator());

  Widget _buildErrorTab(dynamic error) => Center(child: Text('Erreur: $error'));

  Widget _buildProduitList(List<Produit> produits, List<CategorieProduit> categories, bool isLowStockTab, bool showThreshold, String userId) {
    if (produits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchName.isEmpty && _searchCategory == 'Toutes'
                  ? 'Aucun produit trouvé'
                  : 'Aucun résultat pour votre recherche',
              style: const TextStyle(color: Colors.grey),
            ),
            if (_searchName.isNotEmpty || _searchCategory != 'Toutes')
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchName = '';
                    _searchCategory = 'Toutes';
                  });
                },
                child: const Text('Réinitialiser la recherche'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(produitControllerProvider.future),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        itemCount: produits.length,
        itemBuilder: (context, index) {
          final produit = produits[index];
          
          final isLowStock = produit.stockDisponible > 0 && 
                           produit.stockDisponible <= produit.seuilAlerte;
          
          return ProduitWidget(
            product: produit,
            categorieLibelle: _getCategorieLibelle(produit.categorieId, categories), // Ajouter cette ligne
            isLowStock: isLowStock,
            isOutOfStock: produit.stockDisponible <= 0,
            showDefective: false,
            showThreshold: showThreshold,
            onTap: () => _showEditDialog(context, produit, userId),
          );
        },
      ),
    );
  }

  Widget _buildDefectiveList(List<Produit> produits, List<CategorieProduit> categories, String userId) {
    if (produits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchName.isEmpty && _searchCategory == 'Toutes'
                  ? 'Aucun produit défectueux'
                  : 'Aucun résultat pour votre recherche',
              style: const TextStyle(color: Colors.grey),
            ),
            if (_searchName.isNotEmpty || _searchCategory != 'Toutes')
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchName = '';
                    _searchCategory = 'Toutes';
                  });
                },
                child: const Text('Réinitialiser la recherche'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(produitControllerProvider.future),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        itemCount: produits.length,
        itemBuilder: (context, index) {
          final produit = produits[index];
          return ProduitWidget(
            product: produit,
            categorieLibelle: _getCategorieLibelle(produit.categorieId, categories), // Ajouter cette ligne
            isLowStock: produit.stockDisponible > 0 && 
                      produit.stockDisponible <= produit.seuilAlerte,
            isOutOfStock: produit.stockDisponible <= 0,
            showDefective: true,
            showThreshold: true,
            onTap: () => _showEditDialog(context, produit, userId),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => ProduitDialog(userId: userId),
    ).then((_) => ref.refresh(produitControllerProvider));
  }

  void _showEditDialog(BuildContext context, Produit produit, String userId) {
    showDialog(
      context: context,
      builder: (context) => ProduitDialog(produit: produit, userId: userId),
    ).then((_) => ref.refresh(produitControllerProvider));
  }
}