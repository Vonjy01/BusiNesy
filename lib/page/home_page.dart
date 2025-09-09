import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/page/entreprise/entreprise_selection.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';
import 'package:project6/widget/arrivage_list.dart';
import 'package:project6/widget/produit_vendu.dart';
import 'package:project6/widget/stat_card.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _checkingEnterprise = true;

  @override
  void initState() {
    super.initState();
    _checkEnterpriseSelection();
  }

  Future<void> _checkEnterpriseSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final entrepriseId = prefs.getString("entrepriseId");
    
    if (entrepriseId == null && mounted) {
      // Rediriger vers la sélection d'entreprise si aucune n'est sélectionnée
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const EntrepriseSelectionPage()),
        (route) => false,
      );
      return;
    }
    
    setState(() => _checkingEnterprise = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingEnterprise) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authState = ref.watch(authControllerProvider);
    final activeEntrepriseAsync = ref.watch(activeEntrepriseProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Erreur: $error'))),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          drawer: AppDrawer(user: user),
          body: Column(
            children: [
              Header(
                title: 'Page d\'accueil',
                content: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme_light,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(0),
                          ),
                        ),
                        child: activeEntrepriseAsync.when(
                          loading: () => const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          error: (_, __) => const Text(
                            'Erreur de chargement',
                            style: TextStyle(color: Colors.white),
                          ),
                          data: (entreprise) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.business,
                                color: background_theme,
                                size: 20,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                entreprise?.nom ?? 'Aucune entreprise active',
                                style: TextStyle(
                                  color: background_theme,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Réservation',
                              value: '3',
                              icon: Icons.shopify_rounded,
                              color: background_theme,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              title: 'Stock bas',
                              value: '0',
                              icon: Icons.warning_rounded,
                              color: Color.fromARGB(255, 22, 145, 3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      const Text(
                        'Arrivage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: List.generate(5, (i) {
                            final random = Random();
                            final stock = 5 + random.nextInt(20);
                            return ArrivageList(
                              name: 'produit ${i + 1}',
                              category: 'catégorie ${i + 1}',
                              stock: stock,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      const Text(
                        'Dernières ventes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: List.generate(7, (i) {
                            final random = Random().nextInt(100);
                            final prix = Random().nextInt(5000) * 100;

                            return ProduitVendu(
                              product: 'product ${i + 1}',
                              quantity: random,
                              date: '10/06/2025',
                              amount: prix,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],                  
          ),
        );
      },
    );
  }
}
