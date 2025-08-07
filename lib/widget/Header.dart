// lib/widget/header.dart
import 'package:flutter/material.dart';
import 'package:project6/utils/constant.dart';

class Header extends StatelessWidget {
  final String title;
  final Widget? content;
  final bool showDrawerIcon;

  const Header({
    super.key,
    required this.title,
    this.content,
    this.showDrawerIcon = true,
  });

  @override
 @override
Widget build(BuildContext context) {
  return SizedBox(
    height: 150, // Hauteur fixe
    child: Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        gradient: headerGradient,
      ),
      padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showDrawerIcon)
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )
              else
                const SizedBox(width: 48),
              
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              
              const SizedBox(width: 48),
            ],
          ),
          if (content != null) Expanded(child: content!),
        ],
      ),
    ),
  );
}
}