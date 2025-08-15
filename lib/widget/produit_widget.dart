import 'package:flutter/material.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/utils/constant.dart';

class ProduitWidget extends StatelessWidget {
  final Produit product;
  final bool isLowStock;
  final bool isOutOfStock;
  final bool showDefective;
  final bool showThreshold;
  final VoidCallback? onTap;

  const ProduitWidget({
    super.key,
    required this.product,
    this.isLowStock = false,
    this.isOutOfStock = false,
    this.showDefective = false,
    this.showThreshold = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
      shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(12),
  side: BorderSide(
    color: isOutOfStock 
        ? color_error
        : isLowStock 
            ? color_warning 
            : Colors.transparent, // pas de couleur si stock normal
    width: (isOutOfStock || isLowStock) ? 2 : 0, // épaisseur uniquement si bordure
  ),
),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (product.description?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                             'Défectueux : ${product.defectueux.toString()!}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                           if (product.description?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                             'Cat : ${product.categorieId.toString()!}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                    // items: categories.map((c) {
                    //   return DropdownMenuItem(
                    //     value: c.id,
                    //     child: Text(c.libelle),
                    //   );
                      ],
                    ),
                  ),
                  // Icônes d'état
                    Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStockColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            showDefective 
                                ? product.defectueux.toString() 
                                : product.stockDisponible.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                  ),
                ],
              ),
             
            ],
          ),
        ),
      ),
    );
  }

  Color _getStockColor() {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }
}