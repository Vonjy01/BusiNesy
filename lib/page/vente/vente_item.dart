class VenteItem {
  final String id;
  final String produitId;
  final String produitNom;
  final String categorieNom; // Nouveau champ
  final int quantite;
  final int produitRevenu;
  final double prixUnitaire;
  final double beneficeUnitaire;
  final double prixTotal;
  final double beneficeTotal;
  final int etat;

  VenteItem({
    required this.id,
    required this.produitId,
    required this.produitNom,
    required this.categorieNom, // Nouveau
    required this.quantite,
    required this.produitRevenu,
    required this.prixUnitaire,
    required this.beneficeUnitaire,
    required this.prixTotal,
    required this.beneficeTotal,
    required this.etat,
  });

  VenteItem copyWith({
    String? id,
    String? produitId,
    String? produitNom,
    String? categorieNom, // Nouveau
    int? quantite,
    int? produitRevenu,
    double? prixUnitaire,
    double? beneficeUnitaire,
    double? prixTotal,
    double? beneficeTotal,
    int? etat,
  }) {
    return VenteItem(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      produitNom: produitNom ?? this.produitNom,
      categorieNom: categorieNom ?? this.categorieNom, // Nouveau
      quantite: quantite ?? this.quantite,
      produitRevenu: produitRevenu ?? this.produitRevenu,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      beneficeUnitaire: beneficeUnitaire ?? this.beneficeUnitaire,
      prixTotal: prixTotal ?? this.prixTotal,
      beneficeTotal: beneficeTotal ?? this.beneficeTotal,
      etat: etat ?? this.etat,
    );
  }
}