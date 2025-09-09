import 'package:flutter/material.dart';
import 'package:project6/utils/constant.dart';

class Logo extends StatelessWidget {
  final double size; // pour personnaliser la taille

  const Logo({
    Key? key,
    this.size = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: background_theme.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: size / 2, // radius = moitié de la taille
        backgroundImage: AssetImage(logo_path),
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }
}
