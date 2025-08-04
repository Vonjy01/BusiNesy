import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/models/user_model.dart';
import 'package:project6/page/home_page.dart';
import 'package:project6/page/produit_page.dart';
import 'package:project6/page/stock_page.dart';
import 'package:project6/page/vente_page.dart';
import 'package:project6/utils/constant.dart';

class AppDrawer extends ConsumerWidget {
  final User user;
  
  const AppDrawer({super.key, required this.user});
       // accountName: Text(user.nom),
            // accountEmail: Text(user.telephone),
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 180, // Hauteur réduite du header
            padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
              gradient: headerGradient,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                   // Taille de l'avatar augmentée
                  backgroundImage: AssetImage('assets/images/logo1.jpg' ),
                ),
                const SizedBox(width: 15),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      user.nom,
                      style: TextStyle(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.telephone,
                      style: TextStyle(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20.0,
          ),
          ListDrawer(
              context,
              const Icon(
                Icons.home_filled,
                color: color_white,
              ),
              'Accueil',
              const HomePage()),
           ListDrawer(
              context,
              const Icon(
                Icons.inventory_2_outlined,
                color: color_white,
              ),
              'Produit',
              const ProduitPage()),
           ListDrawer(
              context,
              const Icon(
                Icons.point_of_sale,
                color: color_white,
              ),
              'Vente',
              const VentePage()),
               ListDrawer(
              context,
              const Icon(
                Icons.people,
                color: color_white,
              ),
              'Client',
              const VentePage()),
                    ListDrawer(
              context,
              const Icon(
                Icons.help_center_outlined,
                color: color_white,
              ),
              'Aide',
              const HomePage()),
                    ListDrawer(
              context,
              const Icon(
                Icons.settings,
                color: color_white,
              ),
              'Paramètre',
              const ProductsScreen()),
       
        
          const Divider(),
          ListDrawer(
              context,
              const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              'Déconnexion',
              const HomePage()),
               const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget ListDrawer(context, Icon icon, String text, Widget page) {
    return ListTile(
      leading:
          CircleAvatar(backgroundColor: background_theme, radius: 20, child: icon),
      title: Text(text),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}