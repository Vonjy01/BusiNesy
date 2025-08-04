class User {
  final String id;
  final String nom;
  final String telephone;
  final String motDePasse;

  User({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.motDePasse,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
      motDePasse: json['mot_de_passe'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'mot_de_passe': motDePasse,
    };
  }
}