class Produit {
  final String id;
  final String nom;
  final int stock;
  final double prixVente;
  final double prixAchat;
  final double? benefice;
  final String? description;
  final int defectueux;
  final int seuilAlerte; // Nouveau champ
  final String entrepriseId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? categorieId;

  Produit({
    required this.id,
    required this.nom,
    required this.stock,
    required this.prixVente,
    required this.prixAchat,
    this.benefice,
    this.description,
    required this.defectueux,
    this.seuilAlerte = 5, 
    required this.entrepriseId,
    required this.createdAt,
    this.updatedAt,
    this.categorieId,
  });

  // Méthode pour calculer le stock disponible
  int get stockDisponible => stock - defectueux;

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'],
      nom: map['nom'],
      stock: map['stock'],
      prixVente: map['prix_vente'],
      prixAchat: map['prix_achat'],
      benefice: map['benefice'],
      description: map['description'],
      defectueux: map['defectueux'] as int? ?? 0,
      seuilAlerte: map['seuil_alert'] as int? ?? 5,
      entrepriseId: map['entreprise_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      categorieId: map['categorie_id'] is int 
          ? map['categorie_id'] as int?
          : map['categorie_id'] != null 
              ? int.tryParse(map['categorie_id'].toString())
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'stock': stock,
      'prix_vente': prixVente,
      'prix_achat': prixAchat,
      'benefice': benefice,
      'description': description,
      'defectueux': defectueux,
      'seuil_alert': seuilAlerte,
      'entreprise_id': entrepriseId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'categorie_id': categorieId?.toString(),
    };
  }

  Produit copyWith({
    String? nom,
    int? stock,
    double? prixVente,
    double? prixAchat,
    double? benefice,
    String? description,
    int? defectueux,
    int? seuilAlerte,
    DateTime? updatedAt,
    int? categorieId,
  }) {
    return Produit(
      id: id,
      nom: nom ?? this.nom,
      stock: stock ?? this.stock,
      prixVente: prixVente ?? this.prixVente,
      prixAchat: prixAchat ?? this.prixAchat,
      benefice: benefice ?? this.benefice,
      description: description ?? this.description,
      defectueux: defectueux ?? this.defectueux,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      entrepriseId: entrepriseId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categorieId: categorieId ?? this.categorieId,
    );
  }
}