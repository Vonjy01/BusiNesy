// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:project6/controller/command_controller.dart';
// import 'package:project6/controller/fournisseur_controller.dart';
// import 'package:project6/controller/produit_controller.dart';
// import 'package:project6/models/command_model.dart';
// import 'package:project6/models/fournisseur_model.dart';
// import 'package:project6/models/produits_model.dart';
// import 'package:project6/services/database_helper.dart';
// import 'package:uuid/uuid.dart';

// class AddCommandeDialog extends ConsumerStatefulWidget {
//   final String entrepriseId;

//   const AddCommandeDialog({super.key, required this.entrepriseId});

//   @override
//   ConsumerState<AddCommandeDialog> createState() => _AddCommandeDialogState();
// }

// class _AddCommandeDialogState extends ConsumerState<AddCommandeDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _quantiteController = TextEditingController();
//   final _prixAchatController = TextEditingController();
//   final _newProduitController = TextEditingController();
//   DateTime? _dateCommande;
//   Fournisseur? _selectedFournisseur;
//   Produit? _selectedProduit;
//   bool _showNewProduitField = false;
//   bool _isSubmitting = false;
//   final _uuid = const Uuid();

//   @override
//   void dispose() {
//     _quantiteController.dispose();
//     _prixAchatController.dispose();
//     _newProduitController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final fournisseurs = ref.watch(fournisseurControllerProvider);
//     final produits = ref.watch(produitControllerProvider);

//     return AlertDialog(
//       title: const Text('Nouvelle Commande'),
//       content: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildFournisseurDropdown(fournisseurs),
//               const SizedBox(height: 20),
//               _buildProduitSection(produits),
//               const SizedBox(height: 20),
//               _buildQuantiteField(),
//               const SizedBox(height: 20),
//               _buildPrixAchatField(),
//               const SizedBox(height: 20),
//               _buildDateField(),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: _isSubmitting ? null : () => Navigator.pop(context),
//           child: const Text('Annuler'),
//         ),
//         ElevatedButton(
//           onPressed: _isSubmitting ? null : _submitForm,
//           child: _isSubmitting
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//               : const Text('Enregistrer'),
//         ),
//       ],
//     );
//   }

//   Widget _buildFournisseurDropdown(AsyncValue<List<Fournisseur>> fournisseurs) {
//     return fournisseurs.when(
//       loading: () => const Center(child: CircularProgressIndicator()),
//       error: (err, stack) => Text('Erreur: ${err.toString()}'),
//       data: (fournisseurs) {
//         if (fournisseurs.isEmpty) {
//           return const Text('Aucun fournisseur disponible',
//               style: TextStyle(color: Colors.red));
//         }
//         return DropdownButtonFormField<Fournisseur>(
//           decoration: const InputDecoration(
//             labelText: 'Fournisseur *',
//             border: OutlineInputBorder(),
//           ),
//           value: _selectedFournisseur,
//           items: fournisseurs.map((f) {
//             return DropdownMenuItem(
//               value: f,
//               child: Text(f.nom),
//             );
//           }).toList(),
//           onChanged: (f) => setState(() => _selectedFournisseur = f),
//           validator: (value) => value == null ? 'Sélection obligatoire' : null,
//         );
//       },
//     );
//   }

//   Widget _buildProduitSection(AsyncValue<List<Produit>> produits) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (!_showNewProduitField) ...[
//           produits.when(
//             loading: () => const Center(child: CircularProgressIndicator()),
//             error: (err, stack) => Text('Erreur: ${err.toString()}'),
//             data: (produits) {
//               if (produits.isEmpty) {
//                 return const Text('Aucun produit disponible',
//                     style: TextStyle(color: Colors.red));
//               }
//               return DropdownButtonFormField<Produit>(
//                 decoration: const InputDecoration(
//                   labelText: 'Produit existant *',
//                   border: OutlineInputBorder(),
//                 ),
//                 value: _selectedProduit,
//                 items: [
//                   const DropdownMenuItem(
//                     value: null,
//                     child: Text('Sélectionnez un produit'),
//                   ),
//                   ...produits.map((p) {
//                     return DropdownMenuItem(
//                       value: p,
//                       child: Text(p.nom),
//                     );
//                   }).toList(),
//                 ],
//                 onChanged: (p) => setState(() {
//                   _selectedProduit = p;
//                   if (p != null) {
//                     _prixAchatController.text = p.prixUnitaire.toStringAsFixed(2);
//                   }
//                 }),
//                 validator: (value) {
//                   if (!_showNewProduitField && value == null) {
//                     return 'Sélectionnez ou créez un produit';
//                   }
//                   return null;
//                 },
//               );
//             },
//           ),
//           TextButton(
//             onPressed: () => setState(() {
//               _showNewProduitField = true;
//               _selectedProduit = null;
//               _prixAchatController.clear();
//             }),
//             child: const Text('+ Créer un nouveau produit'),
//           ),
//         ] else ...[
//           TextFormField(
//             controller: _newProduitController,
//             decoration: const InputDecoration(
//               labelText: 'Nom du nouveau produit *',
//               border: OutlineInputBorder(),
//             ),
//             validator: (value) {
//               if (_showNewProduitField && (value == null || value.isEmpty)) {
//                 return 'Nom requis';
//               }
//               return null;
//             },
//           ),
//           TextButton(
//             onPressed: () => setState(() {
//               _showNewProduitField = false;
//               _newProduitController.clear();
//             }),
//             child: const Text('← Utiliser un produit existant'),
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildQuantiteField() {
//     return TextFormField(
//       controller: _quantiteController,
//       keyboardType: TextInputType.number,
//       decoration: const InputDecoration(
//         labelText: 'Quantité *',
//         border: OutlineInputBorder(),
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) return 'Quantité requise';
//         final qty = int.tryParse(value);
//         if (qty == null || qty <= 0) return 'Quantité invalide';
//         return null;
//       },
//     );
//   }

//   Widget _buildPrixAchatField() {
//     return TextFormField(
//       controller: _prixAchatController,
//       keyboardType: TextInputType.numberWithOptions(decimal: true),
//       decoration: const InputDecoration(
//         labelText: 'Prix d\'achat unitaire',
//         border: OutlineInputBorder(),
//         hintText: 'Optionnel',
//       ),
//       validator: (value) {
//         if (value != null && value.isNotEmpty) {
//           final prix = double.tryParse(value);
//           if (prix == null) return 'Prix invalide';
//           if (prix <= 0) return 'Doit être positif';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildDateField() {
//     return ListTile(
//       title: Text(_dateCommande == null
//           ? 'Date de commande *'
//           : 'Date: ${_dateCommande!.toLocal().toString().split(' ')[0]}'),
//       trailing: const Icon(Icons.calendar_today),
//       shape: RoundedRectangleBorder(
//         side: const BorderSide(color: Colors.grey),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       onTap: () async {
//         final date = await showDatePicker(
//           context: context,
//           initialDate: DateTime.now(),
//           firstDate: DateTime(2020),
//           lastDate: DateTime(2030),
//         );
//         if (date != null && mounted) {
//           setState(() => _dateCommande = date);
//         }
//       },
//     );
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_dateCommande == null) {
//       _showError('Veuillez sélectionner une date');
//       return;
//     }
//     if (_selectedFournisseur == null) {
//       _showError('Veuillez sélectionner un fournisseur');
//       return;
//     }
//     if (_selectedProduit == null && _newProduitController.text.isEmpty) {
//       _showError('Veuillez sélectionner ou créer un produit');
//       return;
//     }

//     setState(() => _isSubmitting = true);

//     try {
//       // Vérification renforcée de l'entreprise
//       final db = await DatabaseHelper.instance.database;
//       final entreprise = await db.query(
//         'entreprises',
//         where: 'id = ?',
//         whereArgs: [widget.entrepriseId],
//         limit: 1,
//       );

//       if (entreprise.isEmpty) {
//         throw Exception('Entreprise introuvable - ID: ${widget.entrepriseId}');
//       }

//       // Gestion transactionnelle globale
//       await db.transaction((txn) async {
//         String produitId;
        
//         if (_showNewProduitField) {
//           // Création du nouveau produit
//           produitId = _uuid.v4();
//           final newProduit = Produit(
//             id: produitId,
//             nom: _newProduitController.text.trim(),
//             stock: 0,
//             prixUnitaire: _prixAchatController.text.isNotEmpty
//                 ? double.parse(_prixAchatController.text)
//                 : 0.0,
//             entrepriseId: widget.entrepriseId,
//           );

//           await txn.insert('produits', newProduit.toMap());
//         } else {
//           produitId = _selectedProduit!.id;
//         }

//         // Création de la commande
//         final commande = Commande(
//           id: _uuid.v4(),
//           fournisseurId: _selectedFournisseur!.id,
//           produitId: produitId,
//           quantiteCommandee: int.parse(_quantiteController.text),
//           quantiteRecue: null,
//           prixUnitaire: _prixAchatController.text.isNotEmpty
//               ? double.tryParse(_prixAchatController.text)
//               : null,
//           dateCommande: _dateCommande!,
//           dateArrivee: null,
//           etat: 1,
//           entrepriseId: widget.entrepriseId,
//         );

//         await txn.insert('commandes', commande.toMap());
//       });

//       // Rafraîchir les données après insertion
//       ref.invalidate(produitControllerProvider);
//       ref.invalidate(commandeControllerProvider);

//       if (mounted) Navigator.pop(context);
//     } catch (e, stack) {
//       debugPrint('Erreur lors de la création: $e\n$stack');
//       _showError('Erreur technique: ${e.toString()}');
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }

//   void _showError(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }
// }