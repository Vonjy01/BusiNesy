// models/vente_model.dart
class Vente {
  final String id;
  final String produitId;
  final int quantite;
  final int produitRevenu;
  final String? description;
  final double prixTotal;
  final double prixUnitaire;
  final int etat;
  final double benefice;
  final double montantPaye;
  final DateTime dateVente;
  final String? clientId;
  final String userId;
  final String entrepriseId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Vente({
    required this.id,
    required this.produitId,
    required this.quantite,
    this.produitRevenu = 0,
    this.description,
    required this.prixTotal,
    required this.prixUnitaire,
    this.etat = 1,
    required this.benefice,
    required this.montantPaye,
    required this.dateVente,
    this.clientId,
    required this.userId,
    required this.entrepriseId,
    required this.createdAt,
    this.updatedAt,
  });

  // fromMap, toMap, copyWith...
}

// models/vente_session.dart
class VenteSession {
  final String? clientId;
  final DateTime dateVente;
  final String? description;
  final double montantPaye;
  final List<VenteItem> items;

  VenteSession({
    this.clientId,
    required this.dateVente,
    this.description,
    required this.montantPaye,
    required this.items,
  });

  double get total => items.fold(0, (sum, item) => sum + item.prixTotal);
}

// models/vente_item.dart
class VenteItem {
  final String id;
  final String produitId;
  final String produitNom;
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