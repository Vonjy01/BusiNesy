class EtatCommande {
  final int id;
  final String libelle;

  EtatCommande({required this.id, required this.libelle});

  factory EtatCommande.fromMap(Map<String, dynamic> map) {
    return EtatCommande(
      id: map['id'] as int,
      libelle: map['libelle'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
    };
  }
}