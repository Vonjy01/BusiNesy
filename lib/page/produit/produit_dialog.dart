import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/models/produits_model.dart';
import 'package:uuid/uuid.dart';

class ProduitDialog extends ConsumerStatefulWidget {
  final Produit? produit;
  final String userId;
  final String entrepriseId;

  const ProduitDialog({
    super.key, 
    this.produit,
    required this.userId,
    required this.entrepriseId,
  });

  @override
  ConsumerState<ProduitDialog> createState() => _ProduitDialogState();
}

class _ProduitDialogState extends ConsumerState<ProduitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prixVenteController = TextEditingController();
  final _prixAchatController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _beneficeController = TextEditingController();
  final _defectueuxController = TextEditingController();
  final _seuilAlerteController = TextEditingController();

  final _uuid = const Uuid();
  int? _selectedCategorieId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Valeurs par défaut pour nouveau produit
    _seuilAlerteController.text = '5';
    _defectueuxController.text = '0';

    if (widget.produit != null) {
      // Remplissage des valeurs existantes pour modification
      _nomController.text = widget.produit!.nom;
      _prixVenteController.text = widget.produit!.prixVente.toStringAsFixed(2);
      _prixAchatController.text = widget.produit!.prixAchat.toStringAsFixed(2);
      _stockController.text = widget.produit!.stock.toString();
      _defectueuxController.text = widget.produit!.defectueux.toString();
      _beneficeController.text = _calculerBeneficeFromPrix(
        widget.produit!.prixVente, 
        widget.produit!.prixAchat
      );
      _descriptionController.text = widget.produit!.description ?? '';
      _seuilAlerteController.text = widget.produit!.seuilAlerte.toString();
      _selectedCategorieId = widget.produit!.categorieId;
    }

    // Ajouter les listeners pour le calcul automatique du bénéfice
    _prixVenteController.addListener(_calculerBeneficeAutomatique);
    _prixAchatController.addListener(_calculerBeneficeAutomatique);
  }

  @override
  void dispose() {
    // Nettoyer les listeners
    _prixVenteController.removeListener(_calculerBeneficeAutomatique);
    _prixAchatController.removeListener(_calculerBeneficeAutomatique);
    
    _nomController.dispose();
    _prixVenteController.dispose();
    _prixAchatController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _beneficeController.dispose();
    _defectueuxController.dispose();
    _seuilAlerteController.dispose();
    super.dispose();
  }

  // ⚡ CALCUL AUTOMATIQUE du bénéfice
  void _calculerBeneficeAutomatique() {
    final prixVenteText = _prixVenteController.text;
    final prixAchatText = _prixAchatController.text;

    if (prixVenteText.isNotEmpty && prixAchatText.isNotEmpty) {
      final prixVente = double.tryParse(prixVenteText);
      final prixAchat = double.tryParse(prixAchatText);

      if (prixVente != null && prixAchat != null) {
        final benefice = prixVente - prixAchat;
        
        setState(() {
          _beneficeController.text = benefice.toStringAsFixed(2);
        });
        return;
      }
    }
    
    // Si les champs sont vides ou invalides
    setState(() {
      _beneficeController.text = '';
    });
  }

  // ⚡ Méthode utilitaire pour calculer le bénéfice à partir des prix
  String _calculerBeneficeFromPrix(double prixVente, double prixAchat) {
    return (prixVente - prixAchat).toStringAsFixed(2);
  }

  // ⚡ MÉTHODE pour formater les nombres avec 2 décimales
  void _formaterPrix(TextEditingController controller) {
    final text = controller.text;
    if (text.isNotEmpty) {
      final value = double.tryParse(text);
      if (value != null) {
        controller.text = value.toStringAsFixed(2);
        _calculerBeneficeAutomatique(); // Recalculer après formatage
      }
    }
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
                            const SizedBox(height: 16),

              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit ',
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

                  categories.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Erreur de chargement des catégories'),
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Text('Aucune catégorie disponible');
                  }
                  
                  if (!isEditing && _selectedCategorieId == null) {
                    _selectedCategorieId = categories.first.id;
                  }

                  return DropdownButtonFormField<int>(
                    value: _selectedCategorieId,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie ',
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
              
              // Prix d'achat
              TextFormField(
                controller: _prixAchatController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Prix d\'achat ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Calcul immédiat à chaque changement
                  if (value.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _calculerBeneficeAutomatique();
                    });
                  }
                },
                onEditingComplete: () => _formaterPrix(_prixAchatController),
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
              
              // Prix de vente
              TextFormField(
                controller: _prixVenteController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Prix de vente ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Calcul immédiat à chaque changement
                  if (value.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _calculerBeneficeAutomatique();
                    });
                  }
                },
                onEditingComplete: () => _formaterPrix(_prixVenteController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  
                  // ⚡ VALIDATION : Vérifier que le prix de vente >= prix d'achat
                  final prixAchat = double.tryParse(_prixAchatController.text);
                  final prixVente = double.tryParse(value);
                  if (prixAchat != null && prixVente != null && prixVente < prixAchat) {
                    return 'Le prix de vente doit être ≥ au prix d\'achat';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Bénéfice (calculé automatiquement)
              TextFormField(
                controller: _beneficeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Bénéfice ',
                  border: const OutlineInputBorder(),
                  filled: true,
                ),
                readOnly: true, // ⚡ Champ en lecture seule
                style: TextStyle(
                  color: _getBeneficeColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              
         
              const SizedBox(height: 16),
              
              // Stock
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock ',
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
              
              // Défectueux
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
              
              // Seuil d'alerte
              TextFormField(
                controller: _seuilAlerteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seuil d\'alerte stock bas ',
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
              
              // Catégorie
          
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleSubmit(context, isEditing),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Sauvegarder' : 'Ajouter'),
        ),
      ],
    );
  }

  // ⚡ MÉTHODE pour déterminer la couleur du bénéfice
  Color _getBeneficeColor() {
    final beneficeText = _beneficeController.text;
    if (beneficeText.isNotEmpty) {
      final benefice = double.tryParse(beneficeText);
      if (benefice != null) {
        if (benefice > 0) return Colors.green;
        if (benefice < 0) return Colors.red;
        return Colors.orange; // Bénéfice = 0
      }
    }
    return Colors.grey;
  }

  Future<void> _handleSubmit(BuildContext context, bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    // ⚡ VALIDATION FINALE : Vérifier que le bénéfice n'est pas négatif
    final prixAchat = double.tryParse(_prixAchatController.text);
    final prixVente = double.tryParse(_prixVenteController.text);
    if (prixAchat != null && prixVente != null && prixVente < prixAchat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le prix de vente doit être supérieur au prix d\'achat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final produit = Produit(
        id: isEditing ? widget.produit!.id : _uuid.v4(),
        nom: _nomController.text.trim(),
        stock: int.parse(_stockController.text),
        prixVente: double.parse(_prixVenteController.text),
        prixAchat: double.parse(_prixAchatController.text),
        description: _descriptionController.text.trim(),
        defectueux: int.parse(_defectueuxController.text.isEmpty ? '0' : _defectueuxController.text),
        seuilAlerte: int.parse(_seuilAlerteController.text),
        entrepriseId: widget.entrepriseId,
        createdAt: isEditing ? widget.produit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        categorieId: _selectedCategorieId!,
        benefice: double.tryParse(_beneficeController.text),
      );

      final controller = ref.read(produitControllerProvider.notifier);
      
      if (isEditing) {
        await controller.updateProduit(produit, widget.userId);
      } else {
        await controller.addProduit(produit, widget.userId);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}