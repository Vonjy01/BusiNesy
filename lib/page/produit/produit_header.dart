import 'package:flutter/material.dart';
import 'package:project6/utils/constant.dart';

class ProduitHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSearchPressed;

  const ProduitHeader({
    super.key,
    required this.title,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: const BoxDecoration(
        gradient: headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onSearchPressed,
            tooltip: 'Rechercher',
          ),
        ],
      ),
    );
  }
}