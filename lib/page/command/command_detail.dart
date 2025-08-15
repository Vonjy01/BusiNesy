// import 'package:flutter/material.dart';
// import 'package:project6/models/commande_model.dart';
// import 'package:project6/models/etat_commande.dart';
// import 'package:project6/models/fournisseur_model.dart';
// import 'package:project6/utils/constant.dart';

// class CommandeDetail extends StatelessWidget {
//   final Commande commande;
//   final Fournisseur? fournisseur;
//   final EtatCommande etat;

//   const CommandeDetail({
//     super.key,
//     required this.commande,
//     this.fournisseur,
//     required this.etat,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Détails Commande'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Fournisseur: ${fournisseur?.nom ?? 'Inconnu'}',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     if (fournisseur?.telephone != null)
//                       Text('Téléphone: ${fournisseur!.telephone}'),
//                     if (fournisseur?.email != null)
//                       Text('Email: ${fournisseur!.email}'),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Détails Commande',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text('Date commande: ${commande.dateCommande.day}/${commande.dateCommande.month}/${commande.dateCommande.year}'),
//                     if (commande.dateArrivee != null)
//                       Text('Date réception: ${commande.dateArrivee!.day}/${commande.dateArrivee!.month}/${commande.dateArrivee!.year}'),
//                     Text('Statut: ${etat.libelle}'),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Produits commandés',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     // Liste des produits commandés
//                     // À implémenter selon votre structure de données
//                   ],
//                 ),
//               ),
//             ),
//             if (commande.etatId == '1') // Si en attente
//               Padding(
//                 padding: const EdgeInsets.only(top: 16),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                         ),
//                         onPressed: () {
//                           // Marquer comme reçu (statut=2)
//                         },
//                         child: const Text('Marquer comme reçu'),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                         ),
//                         onPressed: () {
//                           // Annuler la commande (statut=4)
//                         },
//                         child: const Text('Annuler'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }