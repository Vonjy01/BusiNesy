import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/widget/produit_item.dart';

class DefectiveProductsView extends ConsumerWidget {
  const DefectiveProductsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produits = ref.watch(produitControllerProvider).value ?? [];
    final defectiveProducts = produits.where((p) => p.defectueux > 0).toList();

    if (defectiveProducts.isEmpty) {
      return const Center(
        child: Text('Aucun produit défectueux'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: defectiveProducts.length,
      itemBuilder: (context, index) {
        final product = defectiveProducts[index];
        return ProduitItem(
          name: product.nom,
          prix: product.prixUnitaire.toStringAsFixed(2),
          currentStock: product.defectueux, // Afficher le stock défectueux
          threshold: 1,
          isLowStock: true,
        );
      },
    );
  }
}