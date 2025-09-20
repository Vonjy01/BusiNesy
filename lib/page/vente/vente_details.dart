import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:project6/controller/etat_commande.dart';
import 'package:project6/controller/vente_controller.dart';
import 'package:project6/controller/client_controller.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/models/vente_model.dart';
import 'package:project6/models/client_model.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/models/categorie_produit_model.dart';
import 'package:project6/page/vente/vente_item.dart';
import 'package:project6/provider/etat_commande_provider.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/utils/constant.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

class VenteDetailPage extends ConsumerStatefulWidget {
  final List<Vente>? ventes;
  final Client? client;
  final String userId;
  final String entrepriseId;
  final String? sessionId;

  const VenteDetailPage({
    Key? key,
    this.ventes,
    this.client,
    required this.userId,
    required this.entrepriseId,
    this.sessionId,
  }) : super(key: key);

  @override
  ConsumerState<VenteDetailPage> createState() => _VenteDetailPageState();
}

class _VenteDetailPageState extends ConsumerState<VenteDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  Client? _selectedClient;
  DateTime _dateVente = DateTime.now();
  double _montantPaye = 0;
  String _description = '';
  String _sessionId = '';
  CategorieProduit? _selectedCategorie;

  List<Produit> _produits = [];
  List<CategorieProduit> _categories = [];
  List<VenteItem> _venteItems = [];
final Set<String> _expandedItems = <String>{};

  String? _currentProduitId;
  int? _currentCategorieId;
  int _currentQuantite = 1;
  int _currentProduitRevenu = 0;
  int _currentEtat = 1;
  double _currentPrixUnitaire = 0;
  double _currentMontantPaye = 0;
  
  // Variables pour la recherche
  String _rechercheNom = '';
  String _rechercheQuantite = '';
  String _rechercheCategorie = '';
  String _rechercheProduitRevenu = '';
  List<VenteItem> _venteItemsFiltres = [];
  bool _rechercheActive = false;

  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _produitRevenuController = TextEditingController();
  final TextEditingController _prixUnitaireController = TextEditingController();
  final TextEditingController _montantPayeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _quantiteController.text = '1';
    _produitRevenuController.text = '0';
    _prixUnitaireController.text = '0';
    _montantPayeController.text = '0';
    
    // Initialiser la session ID
    if (widget.ventes != null && widget.ventes!.isNotEmpty) {
      _sessionId = widget.ventes!.first.sessionId;
    } else if (widget.sessionId != null) {
      _sessionId = widget.sessionId!;
    } else {
      _sessionId = _uuid.v4();
    }
    
    if (widget.ventes != null && widget.ventes!.isNotEmpty) {
      final firstVente = widget.ventes!.first;
      _selectedClient = widget.client;
      _dateVente = firstVente.dateVente;
      _montantPaye = firstVente.montantPaye;
      _description = firstVente.description ?? '';
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVentesWithProductNames().then((_) {
          // Initialiser après le chargement des ventes
          setState(() {
            _venteItemsFiltres = List.from(_venteItems);
          });
        });
      });
    } else if (widget.client != null) {
      _selectedClient = widget.client;
      _venteItemsFiltres = List.from(_venteItems);
    } else {
      _venteItemsFiltres = List.from(_venteItems);
    }
  }

  Future<void> _loadVentesWithProductNames() async {
    final produitsState = ref.read(produitControllerProvider);
    final categoriesState = ref.read(categorieProduitControllerProvider);
    
    produitsState.when(
      data: (produits) {
        categoriesState.when(
          data: (categories) {
            setState(() {
              for (final vente in widget.ventes!) {
                final produit = produits.firstWhere(
                  (p) => p.id == vente.produitId,
                  orElse: () => Produit(
                    id: '', nom: 'Produit inconnu', stock: 0, prixVente: 0, prixAchat: 0,
                    defectueux: 0, entrepriseId: '', createdAt: DateTime.now(),
                    categorieId: null, benefice: 0, seuilAlerte: 5,
                  ),
                );
                
                // Trouver la catégorie du produit
                String categorieNom = 'Non catégorisé';
                if (produit.categorieId != null) {
                  final categorie = categories.firstWhere(
                    (c) => c.id == produit.categorieId,
                    orElse: () => CategorieProduit(
                      id: 0, libelle: 'Inconnu', entrepriseId: '', createdAt: DateTime.now()
                    ),
                  );
                  categorieNom = categorie.libelle;
                }
                
                final quantiteNet = vente.quantite - vente.produitRevenu;
                
                _venteItems.add(VenteItem(
                  id: vente.id,
                  produitId: vente.produitId,
                  produitNom: produit.nom,
                  categorieNom: categorieNom,
                  quantite: vente.quantite,
                  produitRevenu: vente.produitRevenu,
                  prixUnitaire: vente.prixUnitaire,
                  beneficeUnitaire: produit.benefice ?? 0,
                  prixTotal: vente.prixTotal,
                  beneficeTotal: quantiteNet * (produit.benefice ?? 0),
                  etat: vente.etat,
                ));
              }
              _venteItems.sort((a, b) => a.produitNom.compareTo(b.produitNom));
            });
          },
          loading: () {},
          error: (error, stack) {},
        );
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    _produitRevenuController.dispose();
    _prixUnitaireController.dispose();
    _montantPayeController.dispose();
    super.dispose();
  }

  void _onProduitChanged(Produit? produit) {
    if (produit != null) {
      setState(() {
        _currentProduitId = produit.id;
        _currentPrixUnitaire = produit.prixVente;
        _currentMontantPaye = produit.prixVente;
        _prixUnitaireController.text = produit.prixVente.toString();
        _montantPayeController.text = produit.prixVente.toString();
      });
    }
  }

  void _ajouterProduit() async {
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

    final existingItem = _venteItems.firstWhere(
      (item) => item.produitId == _currentProduitId && item.etat == _currentEtat,
      orElse: () => VenteItem(
        id: '',
        produitId: '',
        produitNom: '',
        categorieNom: '',
        quantite: 0,
        produitRevenu: 0,
        prixUnitaire: 0,
        beneficeUnitaire: 0,
        prixTotal: 0,
        beneficeTotal: 0,
        etat: 0,
      ),
    );

    if (existingItem.produitId.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce produit existe déjà dans la commande avec le même état')),
      );
      return;
    }

    // Récupérer les catégories de manière asynchrone
    try {
      final categories = await ref.read(categorieProduitControllerProvider.future);
      final produit = _produits.firstWhere((p) => p.id == _currentProduitId);
      
      String categorieNom = 'Non catégorisé';
      if (produit.categorieId != null) {
        final categorie = categories.firstWhere(
          (c) => c.id == produit.categorieId,
          orElse: () => CategorieProduit(
            id: 0, libelle: 'Inconnu', entrepriseId: '', createdAt: DateTime.now()
          ),
        );
        categorieNom = categorie.libelle;
      }
      
      if (_currentEtat != 2 && _currentEtat != 3 && _currentQuantite > produit.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock insuffisant. Disponible: ${produit.stock}')),
        );
        return;
      }

      final quantiteNet = _currentQuantite - _currentProduitRevenu;
      final prixTotal = quantiteNet * _currentPrixUnitaire;

      final newItem = VenteItem(
        id: _uuid.v4(),
        produitId: _currentProduitId!,
        produitNom: produit.nom,
        categorieNom: categorieNom,
        quantite: _currentQuantite,
        produitRevenu: _currentProduitRevenu,
        prixUnitaire: _currentPrixUnitaire,
        beneficeUnitaire: produit.benefice ?? 0,
        prixTotal: prixTotal,
        beneficeTotal: quantiteNet * (produit.benefice ?? 0),
        etat: _currentEtat,
      );

      setState(() {
        _venteItems.add(newItem);
        _venteItems.sort((a, b) => a.produitNom.compareTo(b.produitNom));
        
        if (_rechercheActive) {
          _appliquerRecherche();
        } else {
          _venteItemsFiltres = List.from(_venteItems);
        }
        
        _resetProduitFields();
      });
      
      _enregistrerVente();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout: $e')),
      );
    }
  }

  void _resetProduitFields() {
    setState(() {
      _currentProduitId = null;
      _currentCategorieId = null;
      _currentQuantite = 1;
      _currentProduitRevenu = 0;
      _currentEtat = 1;
      _currentPrixUnitaire = 0;
      _currentMontantPaye = 0;
      
      _quantiteController.text = '1';
      _produitRevenuController.text = '0';
      _prixUnitaireController.text = '0';
      _montantPayeController.text = '0';
    });
  }

  void _modifierProduit(VenteItem item) {
    showDialog(
      context: context,
      builder: (context) => _buildModifierProduitDialog(item),
    );
  }

  Widget _buildModifierProduitDialog(VenteItem item) {
    final quantiteController = TextEditingController(text: item.quantite.toString());
    final produitRevenuController = TextEditingController(text: item.produitRevenu.toString());
    final prixUnitaireController = TextEditingController(text: item.prixUnitaire.toStringAsFixed(2));
    final beneficeController = TextEditingController(text: item.beneficeUnitaire.toStringAsFixed(2));
    final montantPayeController = TextEditingController(text: item.prixUnitaire.toStringAsFixed(2));
    int selectedEtat = item.etat;

    return AlertDialog(
      title: const Text('Modifier le produit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Produit: ${item.produitNom}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Catégorie: ${item.categorieNom}', style: TextStyle(color: Colors.grey)),
            TextFormField(
              controller: quantiteController,
              decoration: const InputDecoration(
                labelText: 'Quantité *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: prixUnitaireController,
              decoration: const InputDecoration(
                labelText: 'Prix unitaire *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final prix = double.tryParse(value) ?? 0;
                montantPayeController.text = prix.toStringAsFixed(2);
              },
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: montantPayeController,
              decoration: const InputDecoration(
                labelText: 'Montant payé *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: beneficeController,
              decoration: const InputDecoration(
                labelText: 'Bénéfice unitaire *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            Consumer(
              builder: (context, ref, child) {
                final etatsState = ref.watch(etatCommandeProvider);
                return etatsState.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Erreur: $error'),
                  data: (etats) {
                    return DropdownButtonFormField<int>(
                      value: selectedEtat,
                      decoration: const InputDecoration(
                        labelText: 'État',
                        border: OutlineInputBorder(),
                      ),
                      items: etats.map((etat) {
                        return DropdownMenuItem(
                          value: etat.id,
                          child: Text(etat.libelle),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedEtat = value!;
                        });
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            
            if (selectedEtat == 2 || selectedEtat == 3)
              TextFormField(
                controller: produitRevenuController,
                decoration: const InputDecoration(
                  labelText: 'Produit revenu',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            if (selectedEtat == 2 || selectedEtat == 3) const SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final nouvelleQuantite = int.tryParse(quantiteController.text) ?? item.quantite;
            final nouveauProduitRevenu = int.tryParse(produitRevenuController.text) ?? item.produitRevenu;
            final nouveauPrixUnitaire = double.tryParse(prixUnitaireController.text) ?? item.prixUnitaire;
            final nouveauBenefice = double.tryParse(beneficeController.text) ?? item.beneficeUnitaire;
            
            setState(() {
              final index = _venteItems.indexWhere((i) => i.id == item.id);
              if (index != -1) {
                final quantiteNet = nouvelleQuantite - nouveauProduitRevenu;
                
                _venteItems[index] = item.copyWith(
                  quantite: nouvelleQuantite,
                  produitRevenu: nouveauProduitRevenu,
                  prixUnitaire: nouveauPrixUnitaire,
                  beneficeUnitaire: nouveauBenefice,
                  prixTotal: quantiteNet * nouveauPrixUnitaire,
                  beneficeTotal: quantiteNet * nouveauBenefice,
                  etat: selectedEtat,
                );
                
                // TRIER APRÈS MODIFICATION
                _venteItems.sort((a, b) => a.produitNom.compareTo(b.produitNom));
                
                // Mettre à jour la liste filtrée
                if (_rechercheActive) {
                  _appliquerRecherche();
                } else {
                  _venteItemsFiltres = List.from(_venteItems);
                }
              }
            });
            Navigator.of(context).pop();
            // SAUVEGARDE AUTOMATIQUE
            _enregistrerVente();
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _supprimerProduit(VenteItem item, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce produit de la vente ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final venteController = ref.read(venteControllerProvider.notifier);
        
        // SI ÉTAT VALIDÉ OU INCOMPLET, ON DOIT REMETTRE LE STOCK (COMME ANNULATION)
        if (item.etat == 2 || item.etat == 3) {
          // Créer une vente temporaire pour l'annulation
          final venteAnnulation = Vente(
            id: item.id,
            produitId: item.produitId,
            quantite: item.quantite,
            produitRevenu: item.produitRevenu,
            description: 'Suppression - ${item.produitNom}',
            prixTotal: item.prixTotal,
            prixUnitaire: item.prixUnitaire,
            etat: 4, // Annulé
            benefice: item.beneficeTotal,
            montantPaye: 0,
            dateVente: DateTime.now(),
            clientId: _selectedClient?.id,
            userId: widget.userId,
            entrepriseId: widget.entrepriseId,
            sessionId: _sessionId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await venteController.addVente(venteAnnulation, widget.userId);
        }
        
        await venteController.deleteVente(item.id, widget.userId);
        
        setState(() {
          _venteItems.removeWhere((i) => i.id == item.id);
          
          // Mettre à jour la liste filtrée
          if (_rechercheActive) {
            _appliquerRecherche();
          } else {
            _venteItemsFiltres = List.from(_venteItems);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprimé avec succès')),
        );
        
        // SAUVEGARDE AUTOMATIQUE
        _enregistrerVente();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  void _showAjouterProduitDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildAjouterProduitDialog(),
    );
  }

  Widget _buildAjouterProduitDialog() {
    return Consumer(
      builder: (context, ref, child) {
        final categoriesState = ref.watch(categorieProduitControllerProvider);
        final produitsState = ref.watch(produitControllerProvider);
        final etatsState = ref.watch(etatCommandeProvider);
        
        int? selectedCategorieId = _currentCategorieId;
        CategorieProduit? selectedCategorie;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter un produit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    categoriesState.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Erreur: $error'),
                      data: (categories) {
                        if (selectedCategorieId != null) {
                          try {
                            selectedCategorie = categories.firstWhere(
                              (c) => c.id == selectedCategorieId,
                            );
                          } catch (e) {
                            selectedCategorie = null;
                          }
                        }
                        
                        return DropdownSearch<CategorieProduit>(
                          items: categories,
                          selectedItem: selectedCategorie,
                          itemAsString: (CategorieProduit c) => c.libelle,
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                            searchDelay: Duration(milliseconds: 300),
                          ),
                          onChanged: (CategorieProduit? value) {
                            setDialogState(() {
                              selectedCategorie = value;
                              selectedCategorieId = value?.id;
                              _currentCategorieId = value?.id;
                            });
                          },
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
                    
                    if (selectedCategorieId != null)
                      produitsState.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Erreur: $error'),
                        data: (produits) {
                          _produits = produits;
                          List<Produit> produitsFiltres = produits.where((p) => p.categorieId == selectedCategorieId).toList();
                          
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
                    
                    if (selectedCategorieId == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Veuillez d\'abord sélectionner une catégorie',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 12),

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
                              child: Text(etat.libelle),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
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
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _prixUnitaireController,
                      decoration: const InputDecoration(
                        labelText: 'Prix unitaire *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _currentPrixUnitaire = double.tryParse(value) ?? 0;
                          _montantPayeController.text = _currentPrixUnitaire.toStringAsFixed(2);
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _montantPayeController,
                      decoration: const InputDecoration(
                        labelText: 'Montant payé *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _currentMontantPaye = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: _ajouterProduit,
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRechercheDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildRechercheDialog(),
    );
  }

  Widget _buildRechercheDialog() {
    final nomController = TextEditingController(text: _rechercheNom);
    final quantiteController = TextEditingController(text: _rechercheQuantite);
    final produitRevenuController = TextEditingController(text: _rechercheProduitRevenu);
    final categoriesState = ref.watch(categorieProduitControllerProvider);

    return AlertDialog(
      title: const Text('Recherche avancée'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du produit',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _rechercheNom = value,
            ),
            const SizedBox(height: 12),
            
            // Dropdown des catégories pour la recherche
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
                  onChanged: (CategorieProduit? value) {
                    setState(() {
                      _selectedCategorie = value;
                      _rechercheCategorie = value?.libelle ?? '';
                    });
                  },
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: quantiteController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _rechercheQuantite = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: produitRevenuController,
              decoration: const InputDecoration(
                labelText: 'Produit revenu',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _rechercheProduitRevenu = value,
            ),
          ],
        ),
      ),
      actions: [
        if (_rechercheActive)
          TextButton(
            onPressed: () {
              setState(() {
                _rechercheNom = '';
                _rechercheQuantite = '';
                _rechercheProduitRevenu = '';
                _rechercheCategorie = '';
                _selectedCategorie = null;
                _rechercheActive = false;
                _venteItemsFiltres = List.from(_venteItems);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Réinitialiser'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            _appliquerRecherche();
            Navigator.of(context).pop();
          },
          child: const Text('Rechercher'),
        ),
      ],
    );
  }

  double get _totalGeneral {
    return _venteItems.fold(0, (sum, item) => sum + item.prixTotal);
  }

  double get _beneficeTotal {
    return _venteItems.fold(0, (sum, item) => sum + item.beneficeTotal);
  }

  Future<void> _enregistrerVente() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedClient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un client')),
        );
        return;
      }

      if (_venteItems.isEmpty) {
        return; // Ne rien faire si pas de produits
      }

      final venteController = ref.read(venteControllerProvider.notifier);
      final List<Vente> ventes = [];
      final DateTime dateVente = DateTime.now();

      for (final item in _venteItems) {
        final vente = Vente(
          id: item.id,
          produitId: item.produitId,
          quantite: item.quantite,
          produitRevenu: item.produitRevenu,
          description: _description,
          prixTotal: item.prixTotal,
          prixUnitaire: item.prixUnitaire,
          etat: item.etat,
          benefice: item.beneficeTotal,
          montantPaye: _montantPaye / _venteItems.length,
          dateVente: dateVente,
          clientId: _selectedClient!.id,
          userId: widget.userId,
          entrepriseId: widget.entrepriseId,
          sessionId: _sessionId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ventes.add(vente);
      }

      try {
        if (widget.ventes == null) {
          await venteController.addVentesBatch(ventes, widget.userId);
        } else {
          await venteController.deleteVentesBySession(widget.sessionId!, widget.userId);
          await venteController.addVentesBatch(ventes, widget.userId);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente sauvegardée automatiquement')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(clientControllerProvider);
    final categoriesState = ref.watch(categorieProduitControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAjouterProduitDialog,
        backgroundColor: background_theme,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Header(
            title: widget.ventes == null ? 'Nouvelle Vente' : 'Détails Vente',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedClient != null)
                  Text(
                    'Client: ${_selectedClient!.nom}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${_totalGeneral.toStringAsFixed(2)} $devise',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  'Bénéfice: ${_beneficeTotal.toStringAsFixed(2)} $devise',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (_rechercheActive)
                  Text(
                    'Filtre actif (${_venteItemsFiltres.length} résultat(s))',
                    style: const TextStyle(color: Colors.yellow, fontSize: 12),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: _rechercheActive ? Colors.yellow : Colors.white),
                onPressed: _showRechercheDialog,
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (widget.ventes == null) ...[
                      _buildInformationsGenerales(clientsState, categoriesState), 
                      const SizedBox(height: 20),
                    ],

                    if (_venteItemsFiltres.isNotEmpty) _buildListeProduits(),
                    if (_venteItemsFiltres.isEmpty && _venteItems.isNotEmpty) 
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Aucun résultat trouvé', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    if (_venteItems.isEmpty) 
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Aucun produit ajouté', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    if (_venteItems.isNotEmpty) _buildSectionTotaux(),
                    const SizedBox(height: 16),

                    if (_venteItems.isNotEmpty) _buildMontantPayeField(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationsGenerales(AsyncValue<List<Client>> clientsState, AsyncValue<List<CategorieProduit>> categoriesState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations générales',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Affichez la session ID
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.receipt, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Session ID:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _sessionId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _sessionId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session ID copié')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Dropdown des catégories
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
              onChanged: (CategorieProduit? value) {
                setState(() {
                  _selectedCategorie = value;
                  _currentCategorieId = value?.id;
                });
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Filtrer par catégorie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        clientsState.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Erreur: $error'),
          data: (clients) {
            return DropdownSearch<Client>(
              items: clients,
              selectedItem: _selectedClient,
              itemAsString: (Client c) => c.nom,
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchDelay: Duration(milliseconds: 300),
              ),
              onChanged: (Client? value) {
                setState(() {
                  _selectedClient = value;
                });
              },
              validator: (Client? value) {
                if (value == null) {
                  return 'Veuillez sélectionner un client';
                }
                return null;
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Client *',
                  border: OutlineInputBorder(),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        TextFormField(
          initialValue: _description,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _description = value),
          maxLines: 2,
        ),
      ],
    );
  }

Widget _buildListeProduits() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Produits ajoutés', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      
      ..._venteItemsFiltres.map((item) => _buildProduitItem(item)).toList(),
    ],
  );
}

Widget _buildProduitItem(VenteItem item) {
  return FutureBuilder<String>(
    future: _getEtatLibelle(item.etat),
    builder: (context, snapshot) {
      final etatLibelle = snapshot.data ?? 'Chargement...';
      final isExpanded = _expandedItems.contains(item.id);
      
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedItems.remove(item.id);
              } else {
                _expandedItems.add(item.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ligne principale (toujours visible)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.produitNom,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Catégorie: ${item.categorieNom}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Quantité et revenu sur la même ligne
                        Row(
                          children: [
                            Text(
                              'Q: ${item.quantite}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (item.produitRevenu > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                'R: ${item.produitRevenu}',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // État avec couleur selon le statut
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getEtatColor(item.etat),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            etatLibelle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Section dépliée (visible seulement quand on clique)
                if (isExpanded) ...[
                  const Divider(height: 16),
                  _buildDetailsProduit(item),
                ],
                
                // Indicateur de collapse/expand
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}Color _getEtatColor(int etat) {
  switch (etat) {
    case 1: // En cours
      return Colors.blue;
    case 2: // Validé
      return Colors.green;
    case 3: // Incomplet
      return Colors.orange;
    case 4: // Annulé
      return Colors.red;
    default:
      return Colors.grey;
  }
}

Widget _buildDetailsProduit(VenteItem item) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Prix unitaire
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Prix unitaire:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${item.prixUnitaire.toStringAsFixed(2)} $devise'),
        ],
      ),
      const SizedBox(height: 8),
      
      // Bénéfice unitaire
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Bénéfice unitaire:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '${item.beneficeUnitaire.toStringAsFixed(2)} $devise',
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
      const SizedBox(height: 8),
      
      // Total
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${item.prixTotal.toStringAsFixed(2)} $devise'),
        ],
      ),
      const SizedBox(height: 8),
      
      // Bénéfice total
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Bénéfice total:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '${item.beneficeTotal.toStringAsFixed(2)} $devise',
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
      const SizedBox(height: 8),
      
      // Actions (modifier/supprimer)
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _modifierProduit(item),
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _supprimerProduit(item, context),
            tooltip: 'Supprimer',
          ),
        ],
      ),
    ],
  );
}

  Future<String> _getEtatLibelle(int etatId) async {
    try {
      final etatCommandeController = ref.read(etatCommandeControllerProvider.notifier);
      final etat = await etatCommandeController.getEtatById(etatId);
      return etat?.libelle ?? 'Inconnu';
    } catch (e) {
      print('Erreur lors de la récupération de l\'état: $e');
      return 'Inconnu';
    }
  }

  Widget _buildSectionTotaux() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total général:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_totalGeneral.toStringAsFixed(2)} $devise',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bénéfice total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_beneficeTotal.toStringAsFixed(2)} $devise',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nombre de produits:'),
                Text(
                  '${_venteItems.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Affichez la session ID dans les totaux
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Session ID:'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _sessionId,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _appliquerRecherche() {
    setState(() {
      _venteItemsFiltres = _venteItems.where((item) {
        bool matchesNom = true;
        bool matchesCategorie = true;
        bool matchesQuantite = true;
        bool matchesRevenu = true;
        
        // Filtre par nom
        if (_rechercheNom.isNotEmpty) {
          matchesNom = item.produitNom.toLowerCase().contains(_rechercheNom.toLowerCase());
        }
        
        // Filtre par catégorie
        if (_rechercheCategorie.isNotEmpty) {
          matchesCategorie = item.categorieNom.toLowerCase().contains(_rechercheCategorie.toLowerCase());
        }
        
        // Filtre par quantité
        if (_rechercheQuantite.isNotEmpty) {
          matchesQuantite = item.quantite.toString() == _rechercheQuantite;
        }
        
        // Filtre par produit revenu
        if (_rechercheProduitRevenu.isNotEmpty) {
          matchesRevenu = item.produitRevenu.toString() == _rechercheProduitRevenu;
        }
        
        return matchesNom && matchesCategorie && matchesQuantite && matchesRevenu;
      }).toList();
      
      _rechercheActive = _rechercheNom.isNotEmpty || 
                        _rechercheCategorie.isNotEmpty ||
                        _rechercheQuantite.isNotEmpty || 
                        _rechercheProduitRevenu.isNotEmpty;
    });
  }

  Widget _buildMontantPayeField() {
    return TextFormField(
      initialValue: _montantPaye.toString(),
      decoration: const InputDecoration(
        labelText: 'Montant payé *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payment),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty || double.tryParse(value) == null) {
          return 'Montant invalide';
        }

        final montant = double.parse(value);
        if (montant < 0) {
          return 'Le montant ne peut pas être négatif';
        }

        if (montant > _totalGeneral) {
          return 'Le montant payé ne peut pas dépasser le total';
        }

        return null;
      },
      onChanged: (value) {
        setState(() {
          _montantPaye = double.tryParse(value) ?? 0;
        });
      },
    );
  }
}