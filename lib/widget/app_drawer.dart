import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/user_model.dart';
import 'package:project6/page/client_page.dart';
import 'package:project6/page/fournisseur/fournisseur_list.dart';
import 'package:project6/page/home_page.dart';
import 'package:project6/page/produit_page.dart';
import 'package:project6/page/vente_page.dart';
import 'package:project6/utils/constant.dart';

class AppDrawer extends ConsumerWidget {
  final User user;

  const AppDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEntrepriseAsync = ref.watch(activeEntrepriseProvider);

    return Drawer(
      child: Column(
        children: [
          Container(
            height: 180,
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
              gradient: headerGradient,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/images/logo1.jpg'),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: activeEntrepriseAsync.when(
                              loading: () => const CircularProgressIndicator(
                                color: background_theme,
                              ),
                              error: (_, __) => const Text(
                                'Erreur de chargement',
                                style: TextStyle(color: Colors.white),
                              ),
                              data: (entreprise) => Row(
                                children: [
                                  const Icon(Icons.business, color: color_white),
                                  const SizedBox(width: 10),
                                  Text(
                                    entreprise?.nom ?? 'Aucune entreprise active',
                                    style: const TextStyle(
                                      color: color_white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: color_white),
                              const SizedBox(width: 10),
                              Text(
                                user.telephone,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, color: color_white),
                              const SizedBox(width: 10),
                              Text(
                                user.nom,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20.0),
                  ListDrawer(
                    context,
                    const Icon(Icons.home_filled, color: color_white),
                    'Accueil',
                    const HomePage(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.inventory_2_outlined, color: color_white),
                    'Produit',
                    const ProduitPage(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.inventory_2_outlined, color: color_white),
                    'Commande',
                    const ProduitPage(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.point_of_sale, color: color_white),
                    'Vente',
                    const VentePage(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.people, color: color_white),
                    'Clients',
                    const ClientPage(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.people, color: color_white),
                    'Fournisseur',
                    const FournisseurList(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.help_center_outlined, color: color_white),
                    'Aide',
                    const HomePage(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.settings, color: color_white),
                    'Paramètre',
                    const HomePage(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: background_theme,
                      radius: 20,
                      child: Icon(Icons.logout, color: Colors.white),
                    ),
                    title: const Text('Déconnexion'),
                    onTap: () {
                      ref.read(authControllerProvider.notifier).logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget ListDrawer(BuildContext context, Icon icon, String text, Widget page) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: background_theme,
        radius: 20,
        child: icon,
      ),
      title: Text(text),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}
