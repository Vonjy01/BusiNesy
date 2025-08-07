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
      id: json['id'].toString(),
      nom: json['nom'].toString(),
      telephone: json['telephone'].toString(),
      motDePasse: json['mot_de_passe'].toString(),
    );
  }

  Map<String, dynamic> toMap() { // Renommez en toMap pour cohérence
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'mot_de_passe': motDePasse,
    };
  }
}