class Entreprise {
  final String id;
  final String nom;
  final String? adresse;
  final String? image; // facultatif
  final String userId;
  final String motDePasse;
  final bool isActive;

  Entreprise({
    required this.id,
    required this.nom,
    this.adresse,
    this.image,
    required this.userId,
    required this.motDePasse,
    this.isActive = false,
  });

  factory Entreprise.fromMap(Map<String, dynamic> map) {
    return Entreprise(
      id: map['id'],
      nom: map['nom'],
      adresse: map['adresse'],
      image: map['image'],
      userId: map['user_id'],
      motDePasse: map['mot_de_passe'],
      isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'image': image,
      'user_id': userId,
      'mot_de_passe': motDePasse,
      'is_active': isActive ? 1 : 0,
    };
  }
}
