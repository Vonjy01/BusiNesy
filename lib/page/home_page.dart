import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/command_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/page/entreprise/entreprise_selection.dart';
import 'package:project6/provider/produit_provider.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/widget/app_drawer.dart';
import 'package:project6/widget/arrivage_list.dart';
import 'package:project6/widget/commande_recu.dart';
import 'package:project6/widget/stat_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project6/controller/produit_controller.dart';

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
    final commandeState = ref.watch(commandeControllerProvider);

    // Récupérer les données réelles des produits
    final produitsState = ref.watch(produitControllerProvider);
    final lowStockProduits = ref.watch(lowStockProduitsProvider);
    final outOfStockProduits = ref.watch(outOfStockProduitsProvider);

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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: produitsState.when(
                                loading: () => const StatCard(
                                  title: 'Stock bas',
                                  value: '...',
                                  icon: Icons.warning_rounded,
                                  color: color_warning,
                                ),
                                error: (error, stack) => const StatCard(
                                  title: 'Stock bas',
                                  value: 'Erreur',
                                  icon: Icons.error,
                                  color: color_warning,
                                ),
                                data: (produits) => StatCard(
                                  title: 'Stock bas',
                                  value: lowStockProduits.length.toString(),
                                  icon: Icons.warning_rounded,
                                  color: color_warning,
                                ),
                              ),
                            ),
                            Expanded(
                              child: produitsState.when(
                                loading: () => const StatCard(
                                  title: 'Stock epuisé',
                                  value: '...',
                                  icon: Icons.warning_rounded,
                                  color: color_error,
                                ),
                                error: (error, stack) => const StatCard(
                                  title: 'Stock epuisé',
                                  value: 'Erreur',
                                  icon: Icons.error,
                                  color: color_error,
                                ),
                                data: (produits) => StatCard(
                                  title: 'Stock epuisé',
                                  value: outOfStockProduits.length.toString(),
                                  icon: Icons.error,
                                  color: color_error,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Commandes en attente
                        const SizedBox(height: 20.0),
                        const Text(
                          'Commandes en attente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        commandeState.when(
                          loading: () => const SizedBox(
                            height: 120,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stack) => SizedBox(
                            height: 120,
                            child: Center(child: Text('Erreur: $error')),
                          ),
                          data: (commandes) {
                            final enAttente = commandes
                                .where((c) => c.etat == 1)
                                .take(10)
                                .toList();

                         // Pour les commandes en attente vides
if (enAttente.isEmpty) {
  return Container(
    height: 120,
    child: Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,  // Même valeur pour width et height
            height: 60, // Même valeur pour width et height
            decoration: BoxDecoration(
              color: background_theme,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/erreur.jpg',
                width: 40,
                height: 40,
                fit: BoxFit.cover, // Couvre tout le cercle
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Aucune commande en attente',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}
                            return produitsState.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) =>
                                  Text('Erreur produit: $error'),
                              data: (produits) {
                                return SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: enAttente.length,
                                    itemBuilder: (context, index) {
                                      final commande = enAttente[index];
                                      // 🔎 Chercher le produit correspondant
                                      final produit = produits.firstWhere(
                                        (p) => p.id == commande.produitId,
                                      );

                                      return ArrivageList(
                                        name: produit?.nom ?? "Produit inconnu",
                                        category:
                                            "Entreprise ${commande.entrepriseId}",
                                        stock: commande.quantiteCommandee ?? 0,
                                        date: DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(commande.dateCommande),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 10.0),
                        const Text(
                          'Commandes reçues',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        commandeState.when(
                          loading: () => const SizedBox(
                            height: 120,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stack) => SizedBox(
                            height: 120,
                            child: Center(child: Text('Erreur: $error')),
                          ),
                          data: (commandes) {
                            final recues = commandes
                                .where((c) => (c.quantiteRecue ?? 0) > 0)
                                .take(10)
                                .toList();

                            if (recues.isEmpty) {
                              return Container(
                                height: 120,
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: theme_light ,
                                        child: Image.asset(
                                          'assets/images/erreur4.jpg', // Remplace par le chemin de ton image
                                          width: 60,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Aucune commande reçue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return produitsState.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) =>
                                  Text('Erreur produit: $error'),
                              data: (produits) {
                                return SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    itemCount: recues.length,
                                    itemBuilder: (context, index) {
                                      final commande = recues[index];

                                      // Chercher le produit lié
                                      final produit = produits.firstWhere(
                                        (p) => p.id == commande.produitId,
                                      );

                                      return CommandeRecu(
                                        product: produit.nom,
                                        quantiteRecu: commande.quantiteRecue ?? 0,
                                        quantiteCommande: commande.quantiteCommandee,
                                        date: DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(commande.dateCommande),
                                        amount:
                                            (commande.quantiteRecue ?? 0) *
                                            1000, // adapte si tu veux prix réel
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 20.0),
                      ],
                    ),
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