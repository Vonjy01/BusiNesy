import 'package:flutter/material.dart';
import 'package:project6/utils/constant.dart';

class ProduitVendu extends StatelessWidget {
  final String product;
  final int quantity;
  final String date;
  final int amount;

  const ProduitVendu({
    super.key,
    required this.product,
    required this.quantity,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme_light,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.point_of_sale, color: background_theme),
        title: Text('${product} (${quantity})' ),
        subtitle: Text(' $date'),
        trailing: Text(
          '${amount}Ar',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}