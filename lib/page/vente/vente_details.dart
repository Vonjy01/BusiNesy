import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:project6/controller/etat_commande.dart';
import 'package:project6/controller/vente_controller.dart';
import 'package:project6/controller/client_controller.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/etat_commande.dart';
import 'package:project6/models/vente_model.dart';
import 'package:project6/models/client_model.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/models/categorie_produit_model.dart';
import 'package:project6/models/entreprise_model.dart';
import 'package:project6/page/vente/vente_item.dart';
import 'package:project6/provider/etat_commande_provider.dart';
import 'package:project6/widget/Header.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/message_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

enum RevenuFilter { tous, avecRevenu, sansRevenu }

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
  RevenuFilter _rechercheRevenu = RevenuFilter.tous;

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
    
    // Charger les données pour l'entreprise active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeEntreprise = ref.read(activeEntrepriseProvider).value;
      if (activeEntreprise != null) {
        // Charger les catégories et produits
        ref.read(categorieProduitControllerProvider.notifier).loadCategories(activeEntreprise.id);
        ref.read(produitControllerProvider.notifier).loadProduits(activeEntreprise.id);
        
        // Si on a des ventes existantes, charger les données associées
        if (widget.ventes != null && widget.ventes!.isNotEmpty) {
          final firstVente = widget.ventes!.first;
          _selectedClient = widget.client;
          _dateVente = firstVente.dateVente;
          _montantPaye = firstVente.montantPaye;
          _description = firstVente.description ?? '';
          
          // Attendre que les données soient chargées avant de peupler la liste
          _waitForDataAndLoadVentes();
        } else if (widget.client != null) {
          _selectedClient = widget.client;
        }
      }
    });
  }

  Future<void> _waitForDataAndLoadVentes() async {
    // Attendre que les catégories et produits soient chargés
    try {
      await ref.read(categorieProduitControllerProvider.future);
      await ref.read(produitControllerProvider.future);
      
      // Maintenant charger les ventes
      _loadVentesWithProductNames().then((_) {
        if (mounted) {
          setState(() {
            _venteItemsFiltres = List.from(_venteItems);
          });
        }
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _loadVentesWithProductNames() async {
    try {
      final produits = await ref.read(produitControllerProvider.future);
      final categories = await ref.read(categorieProduitControllerProvider.future);
      
      setState(() {
        _venteItems.clear(); // Vider la liste avant de la remplir
        
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
          if (produit.categorieId != null && categories.isNotEmpty) {
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
    } catch (e) {
      print('Erreur lors du chargement des ventes: $e');
    }
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
    Message.error(context, 'Veuillez sélectionner un produit');
    return;
  }

  if (_currentQuantite <= 0) {
    Message.error(context, 'La quantité doit être supérieure à 0');
    return;
  }

  try {
    final categories = await ref.read(categorieProduitControllerProvider.future);
    final produit = _produits.firstWhere((p) => p.id == _currentProduitId);
    
    // Vérification stock
    if (_currentEtat != 2 && _currentEtat != 3 && _currentQuantite > produit.stock) {
      Message.error(context, 'Stock insuffisant. Disponible: ${produit.stock}');
      return;
    }

    final quantiteNet = _currentQuantite - _currentProduitRevenu;
    final prixTotal = quantiteNet * _currentPrixUnitaire;

    final newItem = VenteItem(
      id: _uuid.v4(),
      produitId: _currentProduitId!,
      produitNom: produit.nom,
      categorieNom: categories.firstWhere((c) => c.id == produit.categorieId, orElse: () => CategorieProduit(id: 0, libelle: 'Non catégorisé', entrepriseId: '', createdAt: DateTime.now())).libelle,
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
      _venteItemsFiltres = List.from(_venteItems);
      
      // FORCER LE RAFRAÎCHISSEMENT DE L'AFFICHAGE
      _expandedItems.clear(); // Réinitialiser les éléments étendus
    });

    // SAUVEGARDE AUTOMATIQUE
    await _enregistrerVente();
    
    Message.success(context, 'Produit ajouté avec succès');
    
    // FORCER UN NOUVEAU BUILD
    if (mounted) {
      setState(() {});
    }

  } catch (e) {
    Message.error(context, 'Erreur lors de l\'ajout: ${e.toString()}');
  }
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
            
            // VÉRIFIER SI LE CHANGEMENT D'ÉTAT CRÉERAIT UN DOUBLON
            if (selectedEtat != item.etat) {
              final existingWithNewState = _venteItems.firstWhere(
                (i) => i.produitId == item.produitId && i.etat == selectedEtat,
                orElse: () => VenteItem(
                  id: '', produitId: '', produitNom: '', categorieNom: '',
                  quantite: 0, produitRevenu: 0, prixUnitaire: 0,
                  beneficeUnitaire: 0, prixTotal: 0, beneficeTotal: 0, etat: 0,
                ),
              );
              
              if (existingWithNewState.produitId.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ce produit existe déjà avec l\'état "${_getEtatLibelleSync(selectedEtat)}"'),
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
            }
            
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
      
      // CORRECTION : Utiliser un nouvel ID unique pour l'annulation
      final venteAnnulationId = _uuid.v4();
      
      // SI ÉTAT VALIDÉ OU INCOMPLET, ON DOIT REMETTRE LE STOCK (COMME ANNULATION)
      if (item.etat == 2 || item.etat == 3) {
        // Créer une vente temporaire pour l'annulation avec un NOUVEL ID
        final venteAnnulation = Vente(
          id: venteAnnulationId,
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
      
      // Supprimer la vente originale
      await venteController.deleteVente(item.id, widget.userId);
      
      // FORCER LE RAFRAÎCHISSEMENT DE L'ÉTAT
      setState(() {
        _venteItems.removeWhere((i) => i.id == item.id);
        _expandedItems.remove(item.id); // Retirer de la liste des éléments étendus
        
        // Mettre à jour la liste filtrée
        if (_rechercheActive) {
          _appliquerRecherche();
        } else {
          _venteItemsFiltres = List.from(_venteItems);
        }
      });
      
      // FORCER UN NOUVEAU BUILD IMMÉDIAT
      if (mounted) {
        setState(() {});
      }
      
      Message.success(context, 'Produit supprimé avec succès');
      
      // SAUVEGARDE AUTOMATIQUE
      await _enregistrerVente();
      
    } catch (e) {
      String errorMessage = 'Erreur lors de la suppression';
      
      if (e.toString().contains('UNIQUE constraint failed')) {
        errorMessage = 'Erreur: Cette vente existe déjà dans le système';
      } else if (e.toString().contains('SQLITE_CONSTRAINT')) {
        errorMessage = 'Erreur de base de données. Veuillez réessayer.';
      } else {
        errorMessage = 'Erreur technique. Veuillez réessayer.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      print('Erreur technique complète: $e');
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
                      error: (error, stack) {
                        return Column(
                          children: [
                            Text('Erreur chargement catégories: $error', 
                                 style: TextStyle(color: Colors.red)),
                            ElevatedButton(
                              onPressed: () {
                                final activeEntreprise = ref.read(activeEntrepriseProvider).value;
                                if (activeEntreprise != null) {
                                  ref.read(categorieProduitControllerProvider.notifier)
                                      .loadCategories(activeEntreprise.id);
                                }
                              },
                              child: Text('Réessayer'),
                            ),
                          ],
                        );
                      },
                      data: (categories) {
                        if (categories.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'Aucune catégorie disponible. Veuillez d\'abord créer des catégories.',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        
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
    final categoriesState = ref.watch(categorieProduitControllerProvider);

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.search, color: Colors.blue),
              SizedBox(width: 8),
              Text('Recherche '),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Champ de recherche par nom
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du produit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shopping_bag),
                  ),
                  onChanged: (value) => _rechercheNom = value,
                ),
                const SizedBox(height: 16),
                
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
                          _rechercheCategorie = value?.libelle ?? '';
                        });
                      },
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Catégorie',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                // Filtre de revenu avec radios
                const Text(
                  'Filtrer par revenu:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                
                // Radio pour tous les produits
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Radio<RevenuFilter>(
                    value: RevenuFilter.tous,
                    groupValue: _rechercheRevenu,
                    onChanged: (RevenuFilter? value) {
                      setState(() {
                        _rechercheRevenu = value ?? RevenuFilter.tous;
                      });
                    },
                  ),
                  title: const Text('Tous les produits'),
                  onTap: () {
                    setState(() {
                      _rechercheRevenu = RevenuFilter.tous;
                    });
                  },
                ),
                
                // Radio pour produits avec revenu
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Radio<RevenuFilter>(
                    value: RevenuFilter.avecRevenu,
                    groupValue: _rechercheRevenu,
                    onChanged: (RevenuFilter? value) {
                      setState(() {
                        _rechercheRevenu = value ?? RevenuFilter.tous;
                      });
                    },
                  ),
                  title: const Text('Avec revenu'),
                  subtitle: const Text('Produits avec quantité retournée'),
                  onTap: () {
                    setState(() {
                      _rechercheRevenu = RevenuFilter.avecRevenu;
                    });
                  },
                ),
                
                // Radio pour produits sans revenu
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Radio<RevenuFilter>(
                    value: RevenuFilter.sansRevenu,
                    groupValue: _rechercheRevenu,
                    onChanged: (RevenuFilter? value) {
                      setState(() {
                        _rechercheRevenu = value ?? RevenuFilter.tous;
                      });
                    },
                  ),
                  title: const Text('Sans revenu'),
                  subtitle: const Text('Produits sans retour'),
                  onTap: () {
                    setState(() {
                      _rechercheRevenu = RevenuFilter.sansRevenu;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            // Bouton réinitialiser
            if (_rechercheActive)
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Réinitialiser'),
                onPressed: () {
                  setState(() {
                    _rechercheNom = '';
                    _rechercheCategorie = '';
                    _rechercheRevenu = RevenuFilter.tous;
                    _selectedCategorie = null;
                    _rechercheActive = false;
                    _venteItemsFiltres = List.from(_venteItems);
                  });
                  Navigator.of(context).pop();
                },
              ),
            
            // Bouton annuler
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            
            // Bouton rechercher
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Rechercher'),
              onPressed: () {
                _appliquerRecherche();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
        // Si plus d'items, supprimer toute la session
        if (widget.sessionId != null) {
          final venteController = ref.read(venteControllerProvider.notifier);
          await venteController.deleteVentesBySession(widget.sessionId!, widget.userId);
        }
        return;
      }

      final venteController = ref.read(venteControllerProvider.notifier);
      final List<Vente> ventes = [];
      final DateTime dateVente = DateTime.now();

      for (final item in _venteItems) {
        // Générer un nouvel ID pour éviter les conflits
        final venteId = _uuid.v4();
        
        final vente = Vente(
          id: venteId,
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
        // Supprimer les anciennes ventes de la session
        if (widget.sessionId != null) {
          await venteController.deleteVentesBySession(widget.sessionId!, widget.userId);
        }
        
        // Ajouter les nouvelles ventes
        await venteController.addVentesBatch(ventes, widget.userId);
        
        // Mettre à jour les IDs des items
        for (int i = 0; i < _venteItems.length; i++) {
          _venteItems[i] = _venteItems[i].copyWith(id: ventes[i].id);
        }
        
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Vente sauvegardée automatiquement')),
        // );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: ${e.toString().split(':').first}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écoute automatique du changement d'entreprise
    ref.listen<AsyncValue<Entreprise?>>(
      activeEntrepriseProvider,
      (previous, next) {
        next.whenData((entreprise) {
          if (entreprise != null) {
            // Recharger les données quand l'entreprise change
            ref.read(categorieProduitControllerProvider.notifier).loadCategories(entreprise.id);
            ref.read(produitControllerProvider.notifier).loadProduits(entreprise.id);
          }
        });
      },
    );

    final clientsState = ref.watch(clientControllerProvider);
    final categoriesState = ref.watch(categorieProduitControllerProvider);
    final produitsState = ref.watch(produitControllerProvider);
    final etatsState = ref.watch(etatCommandeControllerProvider);

    // Afficher un loading si les données essentielles sont en cours de chargement
    if (categoriesState.isLoading || produitsState.isLoading || etatsState.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des données...'),
            ],
          ),
        ),
      );
    }

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
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'T: ${money.format(_totalGeneral)} $devise',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'B: ${money.format(_beneficeTotal)} $devise',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ]
                ),
               
                if (_rechercheActive)
                  Text(
                    'Recherche (${_venteItemsFiltres.length} résultat(s))',
                    style: const TextStyle(color: Color.fromARGB(255, 234, 233, 232), fontSize: 12),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: Colors.white),
                onPressed: _showRechercheDialog,
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final activeEntreprise = ref.read(activeEntrepriseProvider).value;
                if (activeEntreprise != null) {
                  await ref.read(categorieProduitControllerProvider.notifier).refreshCategories();
                  await ref.read(produitControllerProvider.notifier).refreshProduits();
                  await ref.read(etatCommandeControllerProvider.notifier).refreshEtats();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      if (widget.ventes == null) ...[
                        _buildInformationsGenerales(clientsState, categoriesState, etatsState), 
                        const SizedBox(height: 20),
                      ],

                      if (_venteItemsFiltres.isNotEmpty) _buildListeProduits(etatsState),
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
                      if (_venteItems.isEmpty && !categoriesState.isLoading && !produitsState.isLoading && !etatsState.isLoading) 
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

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationsGenerales(
    AsyncValue<List<Client>> clientsState, 
    AsyncValue<List<CategorieProduit>> categoriesState,
    AsyncValue<List<EtatCommande>> etatsState,
  ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations générales',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildListeProduits(AsyncValue<List<EtatCommande>> etatsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Produits ajoutés', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        ..._venteItemsFiltres.map((item) => _buildProduitItem(item, etatsState)).toList(),
      ],
    );
  }

  Widget _buildProduitItem(VenteItem item, AsyncValue<List<EtatCommande>> etatsState) {
    return etatsState.when(
      loading: () => _buildProduitItemLoading(item),
      error: (error, stack) => _buildProduitItemError(item, error),
      data: (etats) => _buildProduitItemContent(item, etats),
    );
  }

  Widget _buildProduitItemLoading(VenteItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(item.produitNom),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitItemError(VenteItem item, dynamic error) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 16),
            Expanded(
              child: Text('Erreur: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitItemContent(VenteItem item, List<EtatCommande> etats) {
    final etat = etats.firstWhere(
      (e) => e.id == item.etat,
      orElse: () => EtatCommande(id: 0, libelle: 'Inconnu'),
    );
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
                          etat.libelle,
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
  }

  Color _getEtatColor(int etat) {
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
            Text('${item.prixUnitaire} $devise'),
          ],
        ),
        const SizedBox(height: 8),
        
        // Bénéfice unitaire
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bénéfice unitaire:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${item.beneficeUnitaire} $devise',
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
            Text('${item.prixTotal} $devise'),
          ],
        ),
        const SizedBox(height: 8),
        
        // Bénéfice total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bénéfice total:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${item.beneficeTotal} $devise',
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

  String _getEtatLibelleSync(int etatId) {
    final etats = ref.read(etatCommandeProvider).value;
    if (etats != null) {
      final etat = etats.firstWhere(
        (e) => e.id == etatId,
        orElse: () => EtatCommande(id: 0, libelle: 'Inconnu'),
      );
      return etat.libelle;
    }
    return 'Inconnu';
  }

  void _appliquerRecherche() {
    setState(() {
      _venteItemsFiltres = _venteItems.where((item) {
        bool matchesNom = true;
        bool matchesCategorie = true;
        bool matchesRevenu = true;
        
        // Filtre par nom
        if (_rechercheNom.isNotEmpty) {
          matchesNom = item.produitNom.toLowerCase().contains(_rechercheNom.toLowerCase());
        }
        
        // Filtre par catégorie
        if (_rechercheCategorie.isNotEmpty) {
          matchesCategorie = item.categorieNom.toLowerCase().contains(_rechercheCategorie.toLowerCase());
        }
        
        // Filtre par revenu
        switch (_rechercheRevenu) {
          case RevenuFilter.avecRevenu:
            matchesRevenu = item.produitRevenu > 0;
            break;
          case RevenuFilter.sansRevenu:
            matchesRevenu = item.produitRevenu == 0;
            break;
          case RevenuFilter.tous:
          default:
            matchesRevenu = true;
            break;
        }
        
        return matchesNom && matchesCategorie && matchesRevenu;
      }).toList();
      
      _rechercheActive = _rechercheNom.isNotEmpty || 
                        _rechercheCategorie.isNotEmpty ||
                        _rechercheRevenu != RevenuFilter.tous;
    });
  }
}