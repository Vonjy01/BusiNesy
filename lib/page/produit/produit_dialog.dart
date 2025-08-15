import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/models/categorie_produit_model.dart';
import 'package:project6/provider/entreprise_provider.dart';
import 'package:uuid/uuid.dart';

class ProduitDialog extends ConsumerStatefulWidget {
  final Produit? produit;
  final String userId;

  const ProduitDialog({super.key, this.produit, required this.userId});

  @override
  ConsumerState<ProduitDialog> createState() => _ProduitDialogState();
}

class _ProduitDialogState extends ConsumerState<ProduitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prixController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _beneficeController = TextEditingController();
  final _defectueuxController = TextEditingController();
  final _seuilAlerteController = TextEditingController();

  final _uuid = const Uuid();
  int? _selectedCategorieId;

  @override
  void initState() {
    super.initState();
    
    // Valeurs par défaut pour nouveau produit
    _seuilAlerteController.text = '5';
    _defectueuxController.text = '0';

    if (widget.produit != null) {
      // Remplissage des valeurs existantes pour modification
      _nomController.text = widget.produit!.nom;
      _prixController.text = widget.produit!.prixUnitaire.toString();
      _stockController.text = widget.produit!.stock.toString();
      _defectueuxController.text = widget.produit!.defectueux.toString();
      _beneficeController.text = widget.produit!.benefice?.toString() ?? '';
      _descriptionController.text = widget.produit!.description ?? '';
      _seuilAlerteController.text = widget.produit!.seuilAlerte.toString();
      _selectedCategorieId = widget.produit!.categorieId;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prixController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _beneficeController.dispose();
    _defectueuxController.dispose();
    _seuilAlerteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categorieProduitControllerProvider);
    final isEditing = widget.produit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier Produit' : 'Nouveau Produit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre entier';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _defectueuxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Défectueux',
                  border: OutlineInputBorder(),
                  hintText: '0 par défaut',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                    return 'Nombre entier seulement';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seuilAlerteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seuil d\'alerte stock bas *',
                  border: OutlineInputBorder(),
                  hintText: '5 par défaut',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre entier';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              categories.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Erreur de chargement des catégories'),
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Text('Aucune catégorie disponible');
                  }
                  
                  // Si c'est une création et qu'aucune catégorie n'est encore sélectionnée,
                  // on prend la première catégorie disponible par défaut
                  if (!isEditing && _selectedCategorieId == null) {
                    _selectedCategorieId = categories.first.id;
                  }

                  return DropdownButtonFormField<int>(
                    value: _selectedCategorieId,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie *',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.libelle),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategorieId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une catégorie';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _beneficeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Bénéfice',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => _handleSubmit(context, isEditing),
          child: Text(isEditing ? 'Sauvegarder' : 'Ajouter'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit(BuildContext context, bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    final activeEntreprise = ref.read(activeEntrepriseProvider).value;
    if (activeEntreprise == null) return;

    try {
      final produit = Produit(
        id: isEditing ? widget.produit!.id : _uuid.v4(),
        nom: _nomController.text.trim(),
        stock: int.parse(_stockController.text),
        prixUnitaire: double.parse(_prixController.text),
        description: _descriptionController.text.trim(),
        defectueux: int.parse(_defectueuxController.text.isEmpty ? '0' : _defectueuxController.text),
        seuilAlerte: int.parse(_seuilAlerteController.text),
        entrepriseId: activeEntreprise.id,
        createdAt: isEditing ? widget.produit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        categorieId: _selectedCategorieId!,
        benefice: _beneficeController.text.isNotEmpty
            ? double.parse(_beneficeController.text)
            : null,
      );

      if (isEditing) {
        await ref.read(produitControllerProvider.notifier)
            .updateProduit(produit, widget.userId);
      } else {
        await ref.read(produitControllerProvider.notifier)
            .addProduit(produit, widget.userId);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}