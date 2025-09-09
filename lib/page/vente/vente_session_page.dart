// // page/vente/vente_session_page.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:project6/controller/auth_controller.dart';
// import 'package:project6/controller/entreprise_controller.dart';
// import 'package:project6/controller/produit_controller.dart';
// import 'package:project6/controller/vente_controller.dart';
// import 'package:project6/models/produits_model.dart';
// import 'package:project6/models/vente_model.dart';
// import 'package:project6/models/vente_session.dart';
// import 'package:project6/page/vente/vente_item.dart';

// // page/vente/vente_session_page.dart
// class VenteSessionPage extends ConsumerWidget {
//   const VenteSessionPage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final session = ref.watch(venteSessionProvider);
//     final produits = ref.watch(produitControllerProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Nouvelle Vente'),
//         actions: [
//           if (session != null)
//             IconButton(
//               icon: const Icon(Icons.save),
//               onPressed: () => _saveVente(context, ref),
//             ),
//         ],
//       ),
//       body: session == null
//           ? _buildStartSession(ref)
//           : _buildSessionInProgress(session, produits, ref),
//       floatingActionButton: session != null
//           ? FloatingActionButton(
//               onPressed: () => _showAddProductDialog(context, ref),
//               child: const Icon(Icons.add),
//             )
//           : null,
//     );
//   }

//   Widget _buildStartSession(WidgetRef ref) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
//           const SizedBox(height: 20),
//           const Text('Commencer une nouvelle vente'),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: () => ref.read(venteSessionProvider.notifier).startNewSession(),
//             child: const Text('Démarrer une vente'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSessionInProgress(VenteSessionPage session, AsyncValue<List<Produit>> produits, WidgetRef ref) {
//     return Column(
//       children: [
//         // Header de session
//         _buildSessionHeader(session, ref),
        
//         // Liste des produits
//         Expanded(
//           child: session.items.isEmpty
//               ? _buildEmptyCart()
//               : _buildCartItems(session.items, ref),
//         ),
        
//         // Total et actions
//         _buildSessionFooter(session, ref),
//       ],
//     );
//   }

//   Widget _buildSessionHeader(VenteSession session, WidgetRef ref) {
//     return Card(
//       margin: const EdgeInsets.all(8),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text('Vente en cours', style: TextStyle(fontWeight: FontWeight.bold)),
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => ref.read(venteSessionProvider.notifier).clearSession(),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text('Articles: ${session.items.length} | Total: ${session.total.toStringAsFixed(2)} €'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyCart() {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
//           SizedBox(height: 16),
//           Text('Panier vide', style: TextStyle(color: Colors.grey)),
//           SizedBox(height: 8),
//           Text('Ajoutez des produits pour commencer'),
//         ],
//       ),
//     );
//   }

//   Widget _buildCartItems(List<VenteItem> items, WidgetRef ref) {
//     return ListView.builder(
//       padding: const EdgeInsets.all(8),
//       itemCount: items.length,
//       itemBuilder: (context, index) {
//         final item = items[index];
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//           child: ListTile(
//             title: Text(item.produitNom),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Quantité: ${item.quantite}'),
//                 Text('Prix: ${item.prixTotal.toStringAsFixed(2)} €'),
//                 Text('État: ${_getEtatLibelle(item.etat)}'),
//               ],
//             ),
//             trailing: IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red),
//               onPressed: () => ref.read(venteSessionProvider.notifier).removeItem(item.id),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   String _getEtatLibelle(int etat) {
//     switch (etat) {
//       case 1: return 'En attente';
//       case 2: return 'Validé';
//       case 3: return 'Incomplet';
//       case 4: return 'Annulé';
//       default: return 'Inconnu';
//     }
//   }

//   Widget _buildSessionFooter(VenteSession session, WidgetRef ref) {
//     return Card(
//       margin: const EdgeInsets.all(8),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
//                 Text('${session.total.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.bold)),
//               ],
//             ),
//             const SizedBox(height: 12),
//             TextFormField(
//               decoration: const InputDecoration(
//                 labelText: 'Montant payé',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: TextInputType.number,
//               onChanged: (value) {
//                 final montant = double.tryParse(value) ?? 0;
//                 ref.read(venteSessionProvider.notifier).updateMontantPaye(montant);
//               },
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () => _saveVente(context, ref),
//                 child: const Text('Enregistrer la vente'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showAddProductDialog(BuildContext context, WidgetRef ref) {
//     showDialog(
//       context: context,
//       builder: (context) => const AddProductDialog(),
//     );
//   }

//   Future<void> _saveVente(BuildContext context, WidgetRef ref) async {
//     final session = ref.read(venteSessionProvider);
//     final authState = ref.read(authControllerProvider);
//     final entrepriseState = ref.read(activeEntrepriseProvider);

//     if (session == null || session.items.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Aucun produit dans le panier')),
//       );
//       return;
//     }

//     authState.when(
//       data: (user) {
//         if (user == null) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Utilisateur non connecté')),
//           );
//           return;
//         }

//         entrepriseState.when(
//           data: (entreprise) {
//             if (entreprise == null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Aucune entreprise active')),
//               );
//               return;
//             }

//             final venteController = ref.read(venteControllerProvider.notifier);
//             venteController.saveVenteSession(session, user.id, entreprise.id).then((_) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Vente enregistrée avec succès')),
//               );
//               ref.read(venteSessionProvider.notifier).clearSession();
//               Navigator.pop(context);
//             }).catchError((error) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Erreur: $error')),
//               );
//             });
//           },
//           loading: () => const CircularProgressIndicator(),
//           error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Erreur entreprise: $error')),
//           ),
//         );
//       },
//       loading: () => const CircularProgressIndicator(),
//       error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erreur auth: $error')),
//       ),
//     );
//   }
// }