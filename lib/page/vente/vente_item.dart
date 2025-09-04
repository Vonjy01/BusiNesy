// models/vente_item_model.dart
class VenteItem {
  final String id;
  final String produitId;
  final String produitNom;
  final int quantite;
  final int produitRevenu;
  final double prixUnitaire;
  final double benefice;
  final double prixTotal;
  final double beneficeTotal;

  VenteItem({
    required this.id,
    required this.produitId,
    required this.produitNom,
    required this.quantite,
    this.produitRevenu = 0,
    required this.prixUnitaire,
    required this.benefice,
    required this.prixTotal,
    required this.beneficeTotal,
  });

  VenteItem copyWith({
    String? produitId,
    String? produitNom,
    int? quantite,
    int? produitRevenu,
    double? prixUnitaire,
    double? benefice,
    double? prixTotal,
    double? beneficeTotal,
  }) {
    return VenteItem(
      id: id,
      produitId: produitId ?? this.produitId,
      produitNom: produitNom ?? this.produitNom,
      quantite: quantite ?? this.quantite,
      produitRevenu: produitRevenu ?? this.produitRevenu,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      benefice: benefice ?? this.benefice,
      prixTotal: prixTotal ?? this.prixTotal,
      beneficeTotal: beneficeTotal ?? this.beneficeTotal,
    );
  }
}