import 'package:flutter/material.dart';
import 'package:project6/utils/constant.dart';

class CommandeRecu extends StatelessWidget {
  final String product;
  final int quantiteRecu;
  final int quantiteCommande;
  final String date;
  final int amount;

  const CommandeRecu({
    super.key,
    required this.product,
    required this.quantiteRecu,
    required this.quantiteCommande,

    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.inventory, color: background_theme),
        title: Text(
          product,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Commandé : $quantiteCommande"),
                Text("Reçu : $quantiteRecu"),
              ],
            ),
            Text("Date : $date"),
          ],
        ),
       
      ),
    );
  }
}
