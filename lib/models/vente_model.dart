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

  factory Vente.fromMap(Map<String, dynamic> map) {
    return Vente(
      id: map['id'],
      produitId: map['produit_id'],
      quantite: map['quantite'] as int? ?? 0, // Correction ici
      produitRevenu: map['produit_revenu'] as int? ?? 0, // Correction ici
      description: map['description'],
      prixTotal: (map['prix_total'] as num?)?.toDouble() ?? 0.0, // Correction ici
      prixUnitaire: (map['prix_unitaire'] as num?)?.toDouble() ?? 0.0, // Correction ici
      etat: map['etat'] as int? ?? 1, // Correction ici
      benefice: (map['benefice'] as num?)?.toDouble() ?? 0.0, // Correction ici
      montantPaye: (map['montant_paye'] as num?)?.toDouble() ?? 0.0, // Correction ici
      dateVente: DateTime.parse(map['date_vente'] as String? ?? DateTime.now().toIso8601String()), // Correction ici
      clientId: map['client_id'],
      userId: map['user_id'],
      entrepriseId: map['entreprise_id'],
      createdAt: DateTime.parse(map['created_at'] as String? ?? DateTime.now().toIso8601String()), // Correction ici
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null, // Correction ici
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}