import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/user_model.dart';
import 'package:project6/page/%20historique_stock/historique_stock.dart';
import 'package:project6/page/auth/login_page.dart';
import 'package:project6/page/cat_prod.dart/cat_prod_list.dart';
import 'package:project6/page/client/client_list.dart';
import 'package:project6/page/command/command_list.dart';
import 'package:project6/page/entreprise/entreprise_selection.dart';
import 'package:project6/page/fournisseur/fournisseur_list.dart';
import 'package:project6/page/home_page.dart';
import 'package:project6/page/note/note_list.dart';
import 'package:project6/page/produit/produit_list.dart';
import 'package:project6/page/vente/vente_list.dart';
import 'package:project6/services/database_backup.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                    Logo(size: 90),
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
                                  const Icon(
                                    Icons.business,
                                    color: color_white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    entreprise?.nom ??
                                        'Aucune entreprise active',
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
                    const ProduitList(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.list_alt_rounded, color: color_white),
                    'Commande',
                    const CommandList(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.point_of_sale, color: color_white),
                    'Vente',
                    const VenteList(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.people, color: color_white),
                    'Clients',
                    const ClientList(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.warehouse, color: color_white),
                    'Fournisseur',
                    const FournisseurList(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.category_outlined, color: color_white),
                    'Catégorie produit',
                    const CategorieProduitList(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.menu_book_sharp, color: color_white),
                    'Historique des stock',
                    const HistoriqueStockList(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.help_center_outlined, color: color_white),
                    'Aide',
                    const DatabaseBackupPage(),
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: background_theme,
                      radius: 20,
                      child: Icon(Icons.business, color: color_white,),
                    ),
                    title: const Text('Changer d\'entreprise'),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove("entrepriseId");
                      await prefs.remove("entrepriseNom");

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const EntrepriseSelectionPage(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.note_alt_outlined, color: color_white),
                    'Note',
                    const NoteList(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.settings, color: color_white),
                    'Paramètre',
                    const HomePage(),
                  ),
                  ListDrawer(
                    context,
                    const Icon(Icons.save, color: color_white),
                    'Sauvegarde',
                     DatabaseBackupPage(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: background_theme,
                      radius: 20,
                      child: Icon(Icons.exit_to_app, color: color_white,),
                    ),
                    title: const Text("Déconnexion"),
                    onTap: () async {
                      await ref.read(authControllerProvider.notifier).logout();

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove("entrepriseId");
                      await prefs.remove("entrepriseNom");
                      await prefs.setBool('first_run', true);

                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ), // Utilisez MaterialPageRoute directement
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.grey),
                    ),
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
