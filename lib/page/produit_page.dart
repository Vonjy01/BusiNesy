import 'package:flutter/material.dart';

import 'package:project6/widget/generic_tabview.dart';
import 'package:project6/widget/produit_item.dart';

class ProduitPage extends StatelessWidget {
  const ProduitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericTabView(
      headerTitle: 'Liste des produits',
      tabTitles: ['Tous','Arrivage', 'Stock epuisé'],
      tabViews: [
        InventoryList(),
        OutOfStockList(),
        LowStockList(),

      ],
      tabBarOffsetY: -30, // Ajustement optionnel
    );
  }
}

class InventoryList extends StatelessWidget {
  const InventoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      children: const [
        ProduitItem(
          name: 'T-Shirt Blanc',
          prix: '15000',
          currentStock: 42,
          threshold: 5,
        ),
        ProduitItem(
          name: 'Jean Slim Noir',
          prix: '20000',
          currentStock: 15,
          threshold: 4,
        ),
        ProduitItem(
          name: 'Chaussures de Sport',
          prix: '30000',
          currentStock: 8,
          threshold: 3,
        ),
        ProduitItem(
          name: 'Casquette Baseball',
          prix: '15000',
          isLowStock: true,
          currentStock: 3,
          threshold: 5,
        ),
      ],
    );
  }
}

class LowStockList extends StatelessWidget {
  const LowStockList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ProduitItem(
          name: 'Casquette Baseball',
          prix: '20000',
          currentStock: 3,
          threshold: 5,
          isLowStock: true,
        ),
        ProduitItem(
          name: 'Chaussures de Sport',
          prix: '12000',
          currentStock: 2,
          threshold: 3,
          isLowStock: true,
        ),
      ],
    );
  }
}

class OutOfStockList extends StatelessWidget {
  const OutOfStockList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Aucun produit en rupture de stock',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
