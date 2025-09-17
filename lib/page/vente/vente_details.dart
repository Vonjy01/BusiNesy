import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:project6/controller/vente_controller.dart';
import 'package:project6/controller/client_controller.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/models/vente_model.dart';
import 'package:project6/models/client_model.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/models/categorie_produit_model.dart';
import 'package:project6/models/etat_commande.dart';
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
  List<Produit> _produits = [];
  List<CategorieProduit> _categories = [];
  List<VenteItem> _venteItems = [];

  String? _currentProduitId;
  int? _currentCategorieId;
  int _currentQuantite = 1;
  int _currentProduitRevenu = 0;
  int _currentEtat = 1;

  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _produitRevenuController =
      TextEditingController();
  @override
  void initState() {
    super.initState();

    _quantiteController.text = '1';
    _produitRevenuController.text = '0';

    // INITIALISEZ LA SESSION UNE SEULE FOIS
    if (_sessionId.isEmpty) {
      if (widget.ventes != null && widget.ventes!.isNotEmpty) {
        _sessionId = widget.ventes!.first.sessionId;
        print('Session ID des ventes existantes: $_sessionId');
      } else if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        _sessionId = widget.sessionId!;
        print('Session ID reçu: $_sessionId');
      } else {
        _sessionId = _uuid.v4();
        print('Nouvelle Session ID générée: $_sessionId');
      }
    } else {
      print('Session ID déjà existant conservé: $_sessionId');
    }

    if (widget.ventes != null && widget.ventes!.isNotEmpty) {
      final firstVente = widget.ventes!.first;
      _selectedClient = widget.client;
      _dateVente = firstVente.dateVente;
      _montantPaye = firstVente.montantPaye;
      _description = firstVente.description ?? '';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadVentesWithProductNames();
        }
      });
    } else if (widget.client != null) {
      _selectedClient = widget.client;
    }
  }

  Future<void> _loadVentesWithProductNames() async {
    // Utilisez ref.read ici, pas dans initState
    final produitsState = ref.read(produitControllerProvider);

    produitsState.when(
      data: (produits) {
        if (mounted) {
          setState(() {
            for (final vente in widget.ventes!) {
              final produit = produits.firstWhere(
                (p) => p.id == vente.produitId,
                orElse: () => Produit(
                  id: '',
                  nom: 'Produit inconnu',
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

              final quantiteNet = vente.quantite - vente.produitRevenu;

              _venteItems.add(
                VenteItem(
                  id: vente.id,
                  produitId: vente.produitId,
                  produitNom: produit.nom,
                  quantite: vente.quantite,
                  produitRevenu: vente.produitRevenu,
                  prixUnitaire: vente.prixUnitaire,
                  beneficeUnitaire: produit.benefice ?? 0,
                  prixTotal: vente.prixTotal,
                  beneficeTotal: quantiteNet * (produit.benefice ?? 0),
                  etat: vente.etat,
                ),
              );
            }
          });
        }
      },
      loading: () {},
      error: (error, stack) {},
    );
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

    final existingItem = _venteItems.firstWhere(
      (item) =>
          item.produitId == _currentProduitId && item.etat == _currentEtat,
      orElse: () => VenteItem(
        id: '',
        produitId: '',
        produitNom: '',
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
        const SnackBar(
          content: Text(
            'Ce produit existe déjà dans la commande avec le même état',
          ),
        ),
      );
      return;
    }

    final produit = _produits.firstWhere((p) => p.id == _currentProduitId);

    if (_currentEtat != 2 &&
        _currentEtat != 3 &&
        _currentQuantite > produit.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock insuffisant. Disponible: ${produit.stock}'),
        ),
      );
      return;
    }

    final quantiteNet = _currentQuantite - _currentProduitRevenu;
    final prixTotal = quantiteNet * produit.prixVente;

    final newItem = VenteItem(
      id: _uuid.v4(),
      produitId: _currentProduitId!,
      produitNom: produit.nom,
      quantite: _currentQuantite,
      produitRevenu: _currentProduitRevenu,
      prixUnitaire: produit.prixVente,
      beneficeUnitaire: produit.benefice ?? 0,
      prixTotal: prixTotal,
      beneficeTotal: quantiteNet * (produit.benefice ?? 0),
      etat: _currentEtat,
    );

    setState(() {
      _venteItems.add(newItem);
      _resetProduitFields();
    });

    Navigator.of(context).pop();
  }

  void _resetProduitFields() {
    setState(() {
      _currentProduitId = null;
      _currentCategorieId = null;
      _currentQuantite = 1;
      _currentProduitRevenu = 0;
      _currentEtat = 1;

      _quantiteController.text = '1';
      _produitRevenuController.text = '0';
    });
  }

  void _modifierProduit(VenteItem item) {
    showDialog(
      context: context,
      builder: (context) => _buildModifierProduitDialog(item),
    );
  }

  Widget _buildModifierProduitDialog(VenteItem item) {
    final quantiteController = TextEditingController(
      text: item.quantite.toString(),
    );
    final produitRevenuController = TextEditingController(
      text: item.produitRevenu.toString(),
    );
    final prixUnitaireController = TextEditingController(
      text: item.prixUnitaire.toStringAsFixed(2),
    );
    final beneficeController = TextEditingController(
      text: item.beneficeUnitaire.toStringAsFixed(2),
    );
    int selectedEtat = item.etat;

    return AlertDialog(
      title: const Text('Modifier le produit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Produit: ${item.produitNom}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

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
            if (selectedEtat == 2 || selectedEtat == 3)
              const SizedBox(height: 12),
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
            final nouvelleQuantite =
                int.tryParse(quantiteController.text) ?? item.quantite;
            final nouveauProduitRevenu =
                int.tryParse(produitRevenuController.text) ??
                item.produitRevenu;
            final nouveauPrixUnitaire =
                double.tryParse(prixUnitaireController.text) ??
                item.prixUnitaire;
            final nouveauBenefice =
                double.tryParse(beneficeController.text) ??
                item.beneficeUnitaire;

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
              }
            });
            Navigator.of(context).pop();
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
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce produit de la vente ?',
        ),
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
        await venteController.deleteVente(item.id, widget.userId);

        setState(() {
          _venteItems.removeWhere((i) => i.id == item.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprimé avec succès')),
        );
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
                          List<Produit> produitsFiltres = produits
                              .where(
                                (p) => p.categorieId == selectedCategorieId,
                              )
                              .toList();

                          return DropdownSearch<Produit>(
                            items: produitsFiltres,
                            selectedItem: null,
                            itemAsString: (Produit p) =>
                                '${p.nom} (Stock: ${p.stock}, Prix: ${p.prixVente} $devise)',
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchDelay: const Duration(milliseconds: 300),
                              emptyBuilder: (context, searchEntry) {
                                return const ListTile(
                                  title: Text('Aucun produit trouvé'),
                                  subtitle: Text(
                                    'Aucun produit dans cette catégorie',
                                  ),
                                );
                              },
                            ),
                            onChanged: _onProduitChanged,
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
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
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
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

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Prix: ${produit.prixVente} $devise',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Bénéfice: ${produit.benefice ?? 0} $devise',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Stock disponible: ${produit.stock}',
                                style: TextStyle(
                                  color: produit.stock < 5
                                      ? Colors.red
                                      : Colors.green,
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
                                _currentProduitRevenu =
                                    int.tryParse(value) ?? 0;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un produit')),
      );
      return;
    }

    print('Sauvegarde avec session ID: $_sessionId');

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
        montantPaye: _montantPaye,
        dateVente: dateVente,
        clientId: _selectedClient!.id,
        userId: widget.userId,
        entrepriseId: widget.entrepriseId,
        sessionId: _sessionId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      ventes.add(vente);
      print('Vente créée - Session: ${vente.sessionId}, Produit: ${vente.produitId}');
    }

    try {
      if (widget.ventes == null) {
        await venteController.addVentesBatch(ventes, widget.userId);
      } else {
        await venteController.deleteVentesBySession(_sessionId, widget.userId);
        await venteController.addVentesBatch(ventes, widget.userId);
      }
      
      if (mounted) {
        // NE RECONSTRUISEZ PAS LA PAGE - juste retournez en arrière
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente enregistrée avec succès')),
        );
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

  Widget build(BuildContext context) {
    final clientsState = ref.watch(clientControllerProvider);

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
                const SizedBox(
                  height: 4,
                ), // Réduisez l'espace pour éviter l'overflow
                Text(
                  'Total: ${_totalGeneral.toStringAsFixed(2)} $devise',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  'Bénéfice: ${_beneficeTotal.toStringAsFixed(2)} $devise',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: _enregistrerVente,
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
                      _buildInformationsGenerales(clientsState),
                      const SizedBox(height: 20),
                    ],

                    if (_venteItems.isNotEmpty) _buildListeProduits(),
                    if (_venteItems.isEmpty)
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun produit ajouté',
                              style: TextStyle(color: Colors.grey),
                            ),
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

  Widget _buildInformationsGenerales(AsyncValue<List<Client>> clientsState) {
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
        const Text(
          'Produits ajoutés',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        ..._venteItems
            .map(
              (item) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(item.produitNom),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantité: ${item.quantite}'),
                      if (item.etat == 2 || item.etat == 3)
                        Text('Revenu: ${item.produitRevenu}'),
                      Text(
                        'Prix unitaire: ${item.prixUnitaire.toStringAsFixed(2)} $devise',
                      ),
                      Text(
                        'Bénéfice unitaire: ${item.beneficeUnitaire.toStringAsFixed(2)} $devise',
                      ),
                      Text(
                        'Total: ${item.prixTotal.toStringAsFixed(2)} $devise',
                      ),
                      Text(
                        'Bénéfice total: ${item.beneficeTotal.toStringAsFixed(2)} $devise',
                      ),
                      Text('État: ${_getEtatLibelle(item.etat)}'),
                      // Affichez la session ID pour chaque produit
                      const SizedBox(height: 4),
                      Text(
                        'Session: ${_sessionId.length > 8 ? _sessionId.substring(0, 8) + '...' : _sessionId}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'modifier',
                        child: Text('Modifier'),
                      ),
                      const PopupMenuItem(
                        value: 'supprimer',
                        child: Text('Supprimer'),
                      ),
                    ],
                    onSelected: (String value) {
                      if (value == 'modifier') {
                        _modifierProduit(item);
                      } else if (value == 'supprimer') {
                        _supprimerProduit(item, context);
                      }
                    },
                  ),
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  String _getEtatLibelle(int etatId) {
    switch (etatId) {
      case 1:
        return 'En attente';
      case 2:
        return 'Validé';
      case 3:
        return 'Incomplet';
      case 4:
        return 'Annulé';
      default:
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
