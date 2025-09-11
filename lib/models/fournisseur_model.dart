class Fournisseur {
  final String id;
  final String nom;
  final String? telephone;
  final String? email;
  final String? adresse;
  final String entrepriseId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Fournisseur({
    required this.id,
    required this.nom,
    this.telephone,
    this.email,
    this.adresse,
    required this.entrepriseId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Fournisseur.fromMap(Map<String, dynamic> map) {
    return Fournisseur(
      id: map['id'],
      nom: map['nom'],
      telephone: map['telephone'],
      email: map['email'],
      adresse: map['adresse'],
      entrepriseId: map['entreprise_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'entreprise_id': entrepriseId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
    Fournisseur copyWith({
    String? id,
    String? nom,
    String? telephone,
    String? email,
    String? adresse,
    String? entrepriseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fournisseur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}