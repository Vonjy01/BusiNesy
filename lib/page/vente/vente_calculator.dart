import 'dart:math';

class VenteCalculator {
  static double calculerPrixTotal({
    required int quantite,
    required int produitRevenu,
    required double prixUnitaire,
  }) {
    final quantiteVendue = quantite - produitRevenu;
    return quantiteVendue * prixUnitaire;
  }

  static double calculerBeneficeTotal({
    required int quantite,
    required int produitRevenu,
    required double beneficeUnitaire,
  }) {
    final quantiteVendue = quantite - produitRevenu;
    return quantiteVendue * beneficeUnitaire;
  }

  static double calculerMontantRestant({
    required double prixTotal,
    required double montantPaye,
  }) {
    return max(0, prixTotal - montantPaye);
  }

  static bool validerQuantites({
    required int quantite,
    required int produitRevenu,
    required int stockDisponible,
  }) {
    if (quantite <= 0) return false;
    if (produitRevenu < 0) return false;
    if (produitRevenu > quantite) return false;
    if ((quantite - produitRevenu) > stockDisponible) return false;
    return true;
  }

  static Map<String, dynamic> calculerTousLesMontants({
    required int quantite,
    required int produitRevenu,
    required double prixUnitaire,
    required double beneficeUnitaire,
    required double montantPaye,
  }) {
    final quantiteVendue = quantite - produitRevenu;
    final prixTotal = quantiteVendue * prixUnitaire;
    final beneficeTotal = quantiteVendue * beneficeUnitaire;
    final montantRestant = calculerMontantRestant(
      prixTotal: prixTotal,
      montantPaye: montantPaye,
    );

    return {
      'quantiteVendue': quantiteVendue,
      'prixTotal': prixTotal,
      'beneficeTotal': beneficeTotal,
      'montantRestant': montantRestant,
    };
  }
}