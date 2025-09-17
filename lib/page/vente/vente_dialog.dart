import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/models/categorie_produit_model.dart';
import 'package:project6/models/etat_commande.dart';
import 'package:project6/provider/etat_commande_provider.dart';
import 'package:project6/utils/constant.dart';

class VenteDialog extends ConsumerStatefulWidget {
  final Function(Produit, int, int, int) onProduitAdded;
  final List<Produit> produitsExistants;

  const VenteDialog({
    Key? key,
    required this.onProduitAdded,
    required this.produitsExistants,
  }) : super(key: key);

  @override
  ConsumerState<VenteDialog> createState() => _VenteDialogState();
}

class _VenteDialogState extends ConsumerState<VenteDialog> {
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _produitRevenuController = TextEditingController();

  String? _currentProduitId;
  int? _currentCategorieId;
  int _currentQuantite = 1;
  int _currentProduitRevenu = 0;
  int _currentEtat = 1;

  List<Produit> _produits = [];
  CategorieProduit? _selectedCategorie;

  @override
  void initState() {
    super.initState();
    _quantiteController.text = '1';
    _produitRevenuController.text = '0';
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    _produitRevenuController.dispose();
    super.dispose();
  }

  void _onProduitChanged(Produit? produit) {
    if (produit != null) {
      setState(() {
        _currentProduitId = produit.id;
      });
    }
  }

  void _onCategorieChanged(CategorieProduit? categorie) {
    setState(() {
      _selectedCategorie = categorie;
      _currentCategorieId = categorie?.id;
      _currentProduitId = null; // Reset produit selection when category changes
    });
  }

  void _ajouterProduit() {
    if (_currentProduitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un produit')),
      );
      return;
    }

    if (_currentQuantite <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité doit être supérieure à 0')),
      );
      return;
    }

    // Vérifier si le produit existe déjà dans la commande avec le MÊME ÉTAT
    final produitExist = widget.produitsExistants.firstWhere(
      (p) => p.id == _currentProduitId,
      orElse: () => Produit(
        id: '',
        nom: '',
        stock: 0,
        prixVente: 0,
        prixAchat: 0,
        defectueux: 0,
        entrepriseId: '',
        createdAt: DateTime.now(),
        categorieId: null,
        benefice: 0,
        seuilAlerte: 5,
      ),
    );

    if (produitExist.id.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce produit existe déjà dans la commande')),
      );
      return;
    }

    final produit = _produits.firstWhere((p) => p.id == _currentProduitId);
    
    // Vérifier le stock seulement si l'état n'est pas "revenu"
    if (_currentEtat != 2 && _currentEtat != 3 && _currentQuantite > produit.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock insuffisant. Disponible: ${produit.stock}')),
      );
      return;
    }

    widget.onProduitAdded(produit, _currentQuantite, _currentProduitRevenu, _currentEtat);
    Navigator.of(context).pop();
  }

  void _resetFields() {
    setState(() {
      _currentProduitId = null;
      _currentCategorieId = null;
      _currentQuantite = 1;
      _currentProduitRevenu = 0;
      _currentEtat = 1;
      _selectedCategorie = null;
      
      _quantiteController.text = '1';
      _produitRevenuController.text = '0';
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categorieProduitControllerProvider);
    final produitsState = ref.watch(produitControllerProvider);
    final etatsState = ref.watch(etatCommandeProvider);

    return AlertDialog(
      title: const Text('Ajouter un produit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sélection de la catégorie
            categoriesState.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Erreur: $error'),
              data: (categories) {
                return DropdownSearch<CategorieProduit>(
                  items: categories,
                  selectedItem: _selectedCategorie,
                  itemAsString: (CategorieProduit c) => c.libelle,
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchDelay: Duration(milliseconds: 300),
                  ),
                  onChanged: _onCategorieChanged,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Catégorie *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Sélection du produit (uniquement si une catégorie est sélectionnée)
            if (_currentCategorieId != null)
              produitsState.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Erreur: $error'),
                data: (produits) {
                  _produits = produits;
                  List<Produit> produitsFiltres = produits.where((p) => p.categorieId == _currentCategorieId).toList();
                  
                  return DropdownSearch<Produit>(
                    items: produitsFiltres,
                    selectedItem: null,
                    itemAsString: (Produit p) => '${p.nom} (Stock: ${p.stock}, Prix: ${p.prixVente} $devise)',
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchDelay: const Duration(milliseconds: 300),
                      emptyBuilder: (context, searchEntry) {
                        return const ListTile(
                          title: Text('Aucun produit trouvé'),
                          subtitle: Text('Aucun produit dans cette catégorie'),
                        );
                      },
                    ),
                    onChanged: _onProduitChanged,
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'Produit *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  );
                },
              ),
            
            // Message si aucune catégorie n'est sélectionnée
            if (_currentCategorieId == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Veuillez d\'abord sélectionner une catégorie',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),

            // Sélection de l'état
         // Dans _buildAjouterProduitDialog()
etatsState.when(
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => Text('Erreur: $error'),
  data: (etats) {
    return DropdownButtonFormField<int>(
      value: _currentEtat,
      decoration: const InputDecoration(
        labelText: 'État *',
        border: OutlineInputBorder(),
      ),
      items: etats.map((etat) {
        return DropdownMenuItem(
          value: etat.id,
          child: Text(etat.libelle), // Utilisez le libellé de la base
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          
        });(() {
          _currentEtat = value!;
          if (value == 2 || value == 3) {
            _produitRevenuController.text = '0';
          } else {
            _produitRevenuController.text = '0';
            _currentProduitRevenu = 0;
          }
        });
      },
    );
  },
),
            const SizedBox(height: 12),

            // Informations du produit sélectionné
            if (_currentProduitId != null) 
              produitsState.when(
                data: (produits) {
                  final produit = produits.firstWhere(
                    (p) => p.id == _currentProduitId,
                    orElse: () => Produit(
                      id: '', nom: '', stock: 0, prixVente: 0, prixAchat: 0,
                      defectueux: 0, entrepriseId: '', createdAt: DateTime.now(),
                      categorieId: null, benefice: 0, seuilAlerte: 5,
                    ),
                  );
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Prix: ${produit.prixVente} $devise',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Bénéfice: ${produit.benefice ?? 0} $devise',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stock disponible: ${produit.stock}',
                        style: TextStyle(
                          color: produit.stock < 5 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (error, stack) => const SizedBox(),
              ),

            const SizedBox(height: 12),

            // Quantité et produit revenu
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantiteController,
                    decoration: const InputDecoration(
                      labelText: 'Quantité *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _currentQuantite = int.tryParse(value) ?? 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _produitRevenuController,
                    decoration: const InputDecoration(
                      labelText: 'Produit revenu',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _currentProduitRevenu = int.tryParse(value) ?? 0;
                      });
                    },
                    enabled: _currentEtat == 2 || _currentEtat == 3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _resetFields();
            Navigator.of(context).pop();
          },
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _ajouterProduit,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}