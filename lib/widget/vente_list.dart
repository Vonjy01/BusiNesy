import 'package:flutter/material.dart';

class VenteList extends StatelessWidget {
  final String product;
  final int quantity;
  final String date;
  final double amount;

  const VenteList({
    super.key,
    required this.product,
    required this.quantity,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.point_of_sale, color: Colors.blue),
        title: Text(product),
        subtitle: Text('$quantity × ${amount / quantity}€ - $date'),
        trailing: Text(
          '${amount.toStringAsFixed(2)}€',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}