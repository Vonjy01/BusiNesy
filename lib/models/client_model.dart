class Client {
  final int? id;
  final String nom;
  final String? telephone;
  final String? email;
  final String? adresse;
  final String entrepriseId;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Client({
    this.id,
    required this.nom,
    this.telephone,
    this.email,
    this.adresse,
    required this.entrepriseId,
    this.description,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'entreprise_id': entrepriseId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      telephone: map['telephone'] as String?,
      email: map['email'] as String?,
      adresse: map['adresse'] as String?,
      entrepriseId: map['entreprise_id'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }

  Client copyWith({
    int? id,
    String? nom,
    String? telephone,
    String? email,
    String? adresse,
    String? entrepriseId,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}