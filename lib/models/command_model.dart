class Commande {
  final String id;
  final String fournisseurId;
  final String produitId;
  final int quantiteCommandee;
  final int? quantiteRecue;
  final double? prixUnitaire; // Rendons ce champ nullable
  final DateTime dateCommande;
  final DateTime? dateArrivee;
  final int etat;
  final String entrepriseId;

  Commande({
    required this.id,
    required this.fournisseurId,
    required this.produitId,
    required this.quantiteCommandee,
    this.quantiteRecue,
    this.prixUnitaire, // Maintenant nullable
    required this.dateCommande,
    this.dateArrivee,
    this.etat = 1,
    required this.entrepriseId,
  });

  factory Commande.fromMap(Map<String, dynamic> map) {
    return Commande(
      id: map['id'] as String,
      fournisseurId: map['fournisseur_id'] as String,
      produitId: map['produit_id'] as String,
      quantiteCommandee: map['quantite_command'] as int,
      quantiteRecue: map['quantite_recu'] as int?,
      prixUnitaire: map['prix_unitaire'] as double?, // Conversion nullable
      dateCommande: DateTime.parse(map['date_commande'] as String),
      dateArrivee: map['date_arrivee'] != null 
          ? DateTime.parse(map['date_arrivee'] as String) 
          : null,
      etat: map['etat'] as int,
      entrepriseId: map['entreprise_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fournisseur_id': fournisseurId,
      'produit_id': produitId,
      'quantite_command': quantiteCommandee,
      'quantite_recu': quantiteRecue,
      'prix_unitaire': prixUnitaire, // Peut être null
      'date_commande': dateCommande.toIso8601String(),
      'date_arrivee': dateArrivee?.toIso8601String(),
      'etat': etat,
      'entreprise_id': entrepriseId,
    };
  }
}

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
}