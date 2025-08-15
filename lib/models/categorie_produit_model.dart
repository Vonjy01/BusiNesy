// lib/models/categorie_produit_model.dart
class CategorieProduit {
  final int? id;
  final String libelle;
  final String entrepriseId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CategorieProduit({
    this.id,
    required this.libelle,
    required this.entrepriseId,
    required this.createdAt,
    this.updatedAt,
  });

  factory CategorieProduit.fromMap(Map<String, dynamic> map) {
    return CategorieProduit(
      id: map['id'],
      libelle: map['libelle'],
      entrepriseId: map['entreprise_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
      'entreprise_id': entrepriseId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Méthode copyWith intégrée directement dans le modèle
  CategorieProduit copyWith({
    String? libelle,
    DateTime? updatedAt,
  }) {
    return CategorieProduit(
      id: id,
      libelle: libelle ?? this.libelle,
      entrepriseId: entrepriseId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}