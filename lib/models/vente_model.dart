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
  final String sessionId;
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
    required this.sessionId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Vente.fromMap(Map<String, dynamic> map) {
    return Vente(
      id: map['id'] as String? ?? '',
      produitId: map['produit_id'] as String? ?? '',
      quantite: map['quantite'] as int? ?? 0,
      produitRevenu: map['produit_revenu'] as int? ?? 0,
      description: map['description'] as String?,
      prixTotal: (map['prix_total'] as num?)?.toDouble() ?? 0.0,
      prixUnitaire: (map['prix_unitaire'] as num?)?.toDouble() ?? 0.0,
      etat: map['etat'] as int? ?? 1,
      benefice: (map['benefice'] as num?)?.toDouble() ?? 0.0,
      montantPaye: (map['montant_paye'] as num?)?.toDouble() ?? 0.0,
      dateVente: DateTime.parse(
        map['date_vente'] as String? ?? DateTime.now().toIso8601String(),
      ),
      clientId: map['client_id'] as String?,
      userId: map['user_id'] as String? ?? '',
      entrepriseId: map['entreprise_id'] as String? ?? '',
      sessionId: map['session_id'] as String? ?? '',
      createdAt: DateTime.parse(
        map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

Map<String, dynamic> toMap() {
  return {
    'id': id,
    'produit_id': produitId,
    'quantite': quantite,
    'produit_revenu': produitRevenu,
    'description': description,
    'prix_total': prixTotal,
    'prix_unitaire': prixUnitaire,
    'etat': etat,
    'benefice': benefice,
    'montant_paye': montantPaye,
    'date_vente': dateVente.toIso8601String(),
    'client_id': clientId,
    'user_id': userId,
    'entreprise_id': entrepriseId,
    'session_id': sessionId, // ASSUREZ-VOUS QUE C'EST BIEN LÀ
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

  Vente copyWith({
    String? id,
    String? produitId,
    int? quantite,
    int? produitRevenu,
    String? description,
    double? prixTotal,
    double? prixUnitaire,
    int? etat,
    double? benefice,
    double? montantPaye,
    DateTime? dateVente,
    String? clientId,
    String? userId,
    String? entrepriseId,
    String? sessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vente(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      quantite: quantite ?? this.quantite,
      produitRevenu: produitRevenu ?? this.produitRevenu,
      description: description ?? this.description,
      prixTotal: prixTotal ?? this.prixTotal,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      etat: etat ?? this.etat,
      benefice: benefice ?? this.benefice,
      montantPaye: montantPaye ?? this.montantPaye,
      dateVente: dateVente ?? this.dateVente,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
