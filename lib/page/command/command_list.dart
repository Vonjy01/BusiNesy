// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:project6/controller/auth_controller.dart';
// import 'package:project6/controller/command_controller.dart';
// import 'package:project6/models/command_model.dart';
// import 'package:project6/page/command/add_command_dialog.dart';


// class CommandList extends ConsumerWidget {
//   const CommandList({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final commandesAsync = ref.watch(commandeControllerProvider);
    
//     return Scaffold(
//       appBar: AppBar(title: const Text('Gestion des Commandes')),
//       body: commandesAsync.when(
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (err, stack) => Center(child: Text('Erreur: $err')),
//         data: (commandes) {
//           if (commandes.isEmpty) {
//             return const Center(child: Text('Aucune commande enregistrée'));
//           }
          
//           return ListView.builder(
//             itemCount: commandes.length,
//             itemBuilder: (context, index) {
//               final commande = commandes[index];
//               return Card(
//                 child: ListTile(
//                   title: Text('Commande #${commande.id.substring(0, 6)}'),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Produit: ${commande.produitId}'),
//                       Text('Quantité: ${commande.quantiteCommandee}'),
//                       if (commande.quantiteRecue != null)
//                         Text('Reçu: ${commande.quantiteRecue}'),
//                     ],
//                   ),
//                   trailing: _buildEtatChip(commande.etat),
//                   onTap: () => _showDetails(context, ref, commande),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddCommandeDialog(context, ref),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   Widget _buildEtatChip(int etat) {
//     final colors = {
//       1: Colors.orange, // En attente
//       2: Colors.green,  // Reçu
//       3: Colors.blue,   // Incomplète
//       4: Colors.red,    // Annuler
//     };
    
//     return Chip(
//       label: Text('État $etat'),
//       backgroundColor: colors[etat]?.withOpacity(0.2),
//       labelStyle: TextStyle(color: colors[etat]),
//     );
//   }

//   void _showDetails(BuildContext context, WidgetRef ref, Commande commande) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Détails Commande #${commande.id.substring(0, 6)}'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Fournisseur: ${commande.fournisseurId}'),
//               Text('Produit: ${commande.produitId}'),
//               Text('Quantité commandée: ${commande.quantiteCommandee}'),
//               if (commande.quantiteRecue != null)
//                 Text('Quantité reçue: ${commande.quantiteRecue}'),
// Text('Prix unitaire: ${(commande.prixUnitaire ?? 0).toStringAsFixed(2)}'),
//               Text('Date commande: ${commande.dateCommande.toString()}'),
//               if (commande.dateArrivee != null)
//                 Text('Date réception: ${commande.dateArrivee.toString()}'),
//             ],
//           ),
//           actions: [
//             if (commande.etat == 1) // En attente
//               TextButton(
//                 onPressed: () => _showValidateDialog(context, ref, commande),
//                 child: const Text('Valider réception'),
//               ),
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Fermer'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showValidateDialog(BuildContext context, WidgetRef ref, Commande commande) {
//     final quantiteController = TextEditingController(
//       text: commande.quantiteCommandee.toString(),
//     );
    
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Valider la réception'),
//           content: TextField(
//             controller: quantiteController,
//             keyboardType: TextInputType.number,
//             decoration: const InputDecoration(
//               labelText: 'Quantité reçue',
//               hintText: 'Entrez la quantité effectivement reçue',
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Annuler'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 final quantite = int.tryParse(quantiteController.text) ?? 0;
//                 if (quantite > 0) {
//                   Navigator.pop(context); // Fermer la boîte de dialogue
//                   Navigator.pop(context); // Fermer les détails
                  
//                   await ref.read(commandeControllerProvider.notifier).validerReception(
//                     commandeId: commande.id,
//                     quantiteRecue: quantite,
//                     userId: 'current-user-id', // À remplacer par l'ID réel
//                   );
//                 }
//               },
//               child: const Text('Valider'),
//             ),
//           ],
//         );
//       },
//     );
//   }

// void _showAddCommandeDialog(BuildContext context, WidgetRef ref) {
//   final entrepriseId = ref.read(authControllerProvider).value?.id ?? '';
//   if (entrepriseId.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Entreprise non valide')),
//     );
//     return;
//   }

//   showDialog(
//     context: context,
//     builder: (context) => AddCommandeDialog(entrepriseId: entrepriseId),
//   );
// }
// }