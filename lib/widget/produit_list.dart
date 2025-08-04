import 'package:flutter/material.dart';
import 'package:project6/utils/constant.dart';

class InventoryItem extends StatelessWidget {
  final String name;
  final String prix;
  final int currentStock;
  final int threshold;
  final bool isLowStock;

  const InventoryItem({
    super.key,
    required this.name,
    required this.prix,
    required this.currentStock,
    required this.threshold,
    this.isLowStock = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLowStock ? color_warning : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Builder(builder: (context) {
                  return PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                      const PopupMenuItem(
                        value: 'stock',
                        child: Text('Ajuster stock'),
                      ),
                    ],
                  );
                }),
              ],
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock actuel: $currentStock',
                      style: TextStyle(
                        color: currentStock == 0
                            ? color_error
                            : currentStock <= threshold
                                ? color_warning
                                : color_success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Seuil d\'alerte: $threshold',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    gradient: btn_gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 24.0),
                    child: Text(
                      '$prix $devise',
                      style: const TextStyle(
                        color: Colors.white, // texte en blanc ou autre
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
