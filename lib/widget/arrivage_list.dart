import 'package:flutter/material.dart';
import 'package:project6/utils/constant.dart';

class ArrivageList extends StatelessWidget {
  final String name;
  final String category;
  final int stock;

  const ArrivageList({
    super.key,
    required this.name,
    required this.category,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        color: theme_light,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
         
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
             
              Text(
                'Nombre: $stock',
                style: const TextStyle(
                  color: background_theme,
                ),
              ),
               const Text(
                '05-06-2025',
                style: TextStyle(
                ),
              ),
            ],
          ),
          // trailing: PopupMenuButton(
          //   icon: const Icon(Icons.more_vert),
          //   itemBuilder: (context) => [
          //     const PopupMenuItem(
          //       value: 'edit',
          //       child: Text('Modifier'),
          //     ),
          //     const PopupMenuItem(
          //       value: 'delete',
          //       child: Text('Supprimer'),
          //     ),
          //     const PopupMenuItem(
          //       value: 'stock',
          //       child: Text('Ajuster stock'),
          //     ),
          //   ],
          // ),
        ),
      ),
    );
  }
}