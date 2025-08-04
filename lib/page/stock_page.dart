import 'package:flutter/material.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/stock_produit.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Filtrer les produits...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: const [
                ProductListItem(
                  name: 'T-Shirt Blanc',
                  category: 'Vêtements',
                  price: 19.99,
                  stock: 42,
                  image: logo_path,
                ),
                ProductListItem(
                  name: 'Jean Slim Noir',
                  category: 'Vêtements',
                  price: 49.99,
                  stock: 15,
                  image: logo_path,
                ),
                ProductListItem(
                  name: 'Chaussures de Sport',
                  category: 'Chaussures',
                  price: 89.99,
                  stock: 8,
                  image: logo_path,
                ),
                ProductListItem(
                  name: 'Casquette Baseball',
                  category: 'Accessoires',
                  price: 24.99,
                  stock: 3,
                  image: logo_path,
                ),
                ProductListItem(
                  name: 'Sac à Dos',
                  category: 'Accessoires',
                  price: 39.99,
                  stock: 12,
                  image: logo_path,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}