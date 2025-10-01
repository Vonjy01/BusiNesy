import 'package:flutter/material.dart';
import 'package:project6/utils/constant.dart';

class ArrivageList extends StatelessWidget {
  final String name;
  final String category;
  final int stock;
  final String date;

  const ArrivageList({
    super.key,
    required this.name,
    required this.category,
    required this.stock,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        elevation: 3,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom du produit
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: background_theme,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

            
              Row(
                children: [
                  const Icon(Icons.inventory_2, size: 16, color: background_theme),
                  const SizedBox(width: 5),
                  Text(
                    "Quantité : $stock",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 15, color: Colors.blueGrey),
                  const SizedBox(width: 5),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
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
}
