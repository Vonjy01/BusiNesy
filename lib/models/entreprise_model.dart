class Entreprise {
  final String id;
  final String nom;
  final String? adresse;
  final String userId;

  Entreprise({
    required this.id,
    required this.nom,
    this.adresse,
    required this.userId,
  });

  factory Entreprise.fromJson(Map<String, dynamic> json) {
    return Entreprise(
      id: json['id'].toString(),
      nom: json['nom'] as String,
      adresse: json['adresse'] as String?,
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'user_id': userId,
    };
  }
}