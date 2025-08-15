import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/page/produit/produit_dialog.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/generic_tabview.dart';
import 'package:project6/widget/produit_widget.dart';

class ProduitList extends ConsumerStatefulWidget {
  const ProduitList({Key? key}) : super(key: key);

  @override
  ConsumerState<ProduitList> createState() => _ProduitListState();
}

class _ProduitListState extends ConsumerState<ProduitList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(produitControllerProvider.notifier).loadProduits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final produitsState = ref.watch(produitControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => _buildLoadingScreen(),
      error: (error, stack) => _buildErrorScreen(error),
      data: (user) {
        if (user == null) return _buildNoUserScreen();

        return produitsState.when(
          loading: () => _buildScaffold(
            context,
            user.id,
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
            tabViews: [
              _buildErrorTab(error),
              _buildErrorTab(error),
              _buildErrorTab(error),
              _buildErrorTab(error),
            ],
          ),
          data: (produits) {
            // Utilise le seuil d'alerte spécifique à chaque produit
            final tousProduits = produits;
            final stockBas = produits.where((p) => 
              p.stockDisponible > 0 && p.stockDisponible <= p.seuilAlerte).toList();
            final epuise = produits.where((p) => p.stockDisponible <= 0).toList();
            final defectueux = produits.where((p) => p.defectueux > 0).toList();

            return _buildScaffold(
              context,
              user.id,
              tabViews: [
                _buildProduitList(tousProduits, false, false),
                _buildProduitList(stockBas, true, true), // Affiche le seuil pour stock bas
                _buildProduitList(epuise, false, false),
                _buildDefectiveList(defectueux),
              ],
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
    required List<Widget> tabViews,
  }) {
    return Scaffold(
      body: GenericTabView(
        headerTitle: 'Gestion des produits',
        tabTitles: const ['Tous', 'Bas', 'Épuisé', 'Défectueux'],
        tabViews: tabViews,
        tabBarOffsetY: -30,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, userId),
      child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: background_theme,

      ),
    );
  }

  Widget _buildLoadingTab() => const Center(child: CircularProgressIndicator());

  Widget _buildErrorTab(dynamic error) => Center(child: Text('Erreur: $error'));

  Widget _buildProduitList(List<Produit> produits, bool isLowStockTab, bool showThreshold) {
    if (produits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Aucun produit trouvé',
            style: TextStyle(color: Colors.grey),
          ),
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
          
          // Détermine si le produit est en stock bas selon son seuil personnel
          final isLowStock = produit.stockDisponible > 0 && 
                           produit.stockDisponible <= produit.seuilAlerte;
          
          return ProduitWidget(
            product: produit,
            isLowStock: isLowStock,
            isOutOfStock: produit.stockDisponible <= 0,
            showDefective: false,
            showThreshold: showThreshold,
            onTap: () => _showEditDialog(context, produit, ref.read(authControllerProvider).value?.id ?? ''),
          );
        },
      ),
    );
  }

  Widget _buildDefectiveList(List<Produit> produits) {
    if (produits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Aucun produit défectueux',
            style: TextStyle(color: Colors.grey),
          ),
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
            isLowStock: produit.stockDisponible > 0 && 
                      produit.stockDisponible <= produit.seuilAlerte,
            isOutOfStock: produit.stockDisponible <= 0,
            showDefective: true,
            showThreshold: true,
            onTap: () => _showEditDialog(context, produit, ref.read(authControllerProvider).value?.id ?? ''),
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