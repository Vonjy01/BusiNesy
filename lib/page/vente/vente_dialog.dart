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
import 'package:uuid/uuid.dart';

class VenteDialog extends ConsumerStatefulWidget {
  final Vente? vente;
  final String userId;
  final String entrepriseId;

  const VenteDialog({
    Key? key,
    this.vente,
    required this.userId,
    required this.entrepriseId,
  }) : super(key: key);

  @override
  ConsumerState<VenteDialog> createState() => _VenteDialogState();
}

class _VenteDialogState extends ConsumerState<VenteDialog> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  late String _clientId;
  late DateTime _dateVente;
  late int _etat;
  late double _montantPaye;
  String _description = '';

  List<Client> _clients = [];
  List<Produit> _produits = [];
  List<Produit> _produitsFiltres = [];
  List<EtatCommande> _etats = [];
  List<CategorieProduit> _categories = [];
  List<VenteItem> _venteItems = [];

  // Variables pour le produit en cours de sélection
  String? _currentProduitId;
  int? _currentCategorieId;
  int _currentQuantite = 1;
  int _currentProduitRevenu = 0;
  double _currentPrixUnitaire = 0;
  double _currentBenefice = 0;

  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _produitRevenuController = TextEditingController();
  final TextEditingController _prixUnitaireController = TextEditingController();
  final TextEditingController _beneficeController = TextEditingController();

@override
void initState() {
  super.initState();
  _dateVente = DateTime.now();
  _etat = 1;
  _montantPaye = 0;
  _clientId = '';

  if (widget.vente != null) {
    _clientId = widget.vente!.clientId ?? '';
    _montantPaye = widget.vente!.montantPaye;
    _dateVente = widget.vente!.dateVente;
    _etat = widget.vente!.etat;
    _description = widget.vente!.description ?? '';
    
    // Charger le produit existant pour la modification
    _loadExistingVente();
  }
}

void _loadExistingVente() {
  // Pour la modification, ajouter le produit existant à la liste
  if (widget.vente != null) {
    final item = VenteItem(
      id: widget.vente!.id,
      produitId: widget.vente!.produitId,
      produitNom: 'Produit à charger', // Vous devrez récupérer le nom réel
      quantite: widget.vente!.quantite,
      produitRevenu: widget.vente!.produitRevenu,
      prixUnitaire: widget.vente!.prixUnitaire,
      benefice: widget.vente!.benefice,
      prixTotal: widget.vente!.prixTotal,
      beneficeTotal: widget.vente!.benefice,
    );
    
    _venteItems.add(item);
    
    // Pré-remplir les champs
    _currentProduitId = widget.vente!.produitId;
    _currentQuantite = widget.vente!.quantite;
    _currentProduitRevenu = widget.vente!.produitRevenu;
    _currentPrixUnitaire = widget.vente!.prixUnitaire;
    _currentBenefice = widget.vente!.benefice;
    
    _quantiteController.text = _currentQuantite.toString();
    _produitRevenuController.text = _currentProduitRevenu.toString();
    _prixUnitaireController.text = _currentPrixUnitaire.toStringAsFixed(2);
    _beneficeController.text = _currentBenefice.toStringAsFixed(2);
  }
}
  @override
  void dispose() {
    _quantiteController.dispose();
    _produitRevenuController.dispose();
    _prixUnitaireController.dispose();
    _beneficeController.dispose();
    super.dispose();
  }

  void _filtrerProduitsParCategorie(int? categorieId) {
    setState(() {
      _currentCategorieId = categorieId;
      if (categorieId == null) {
        _produitsFiltres = _produits;
      } else {
        _produitsFiltres = _produits.where((produit) => produit.categorieId == categorieId).toList();
      }
    });
  }

  void _onProduitChanged(Produit? produit) {
    if (produit != null) {
      setState(() {
        _currentProduitId = produit.id;
        _currentPrixUnitaire = produit.prixVente;
        _currentBenefice = produit.benefice ?? 0;
        
        _prixUnitaireController.text = _currentPrixUnitaire.toStringAsFixed(2);
        _beneficeController.text = _currentBenefice.toStringAsFixed(2);
        
        // Réinitialiser la quantité si elle dépasse le stock
        if (_currentQuantite > produit.stock) {
          _currentQuantite = 1;
          _quantiteController.text = '1';
        }
      });
    }
  }

  void _onPrixUnitaireChanged(String value) {
    final prix = double.tryParse(value) ?? 0;
    setState(() {
      _currentPrixUnitaire = prix;
    });
  }

  void _onBeneficeChanged(String value) {
    final benefice = double.tryParse(value) ?? 0;
    setState(() {
      _currentBenefice = benefice;
    });
  }

  void _onQuantiteChanged(String value) {
    final quantite = int.tryParse(value) ?? 1;
    setState(() {
      _currentQuantite = quantite;
    });
  }

  void _onProduitRevenuChanged(String value) {
    final revenu = int.tryParse(value) ?? 0;
    setState(() {
      _currentProduitRevenu = revenu;
    });
  }

  void _ajouterProduit() {
    if (_currentProduitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un produit')),
      );
      return;
    }

    final produit = _produits.firstWhere((p) => p.id == _currentProduitId);
    final quantiteNet = _currentQuantite - _currentProduitRevenu;
    final prixTotal = quantiteNet * _currentPrixUnitaire;
    final beneficeTotal = quantiteNet * _currentBenefice;

    final newItem = VenteItem(
      id: _uuid.v4(),
      produitId: _currentProduitId!,
      produitNom: produit.nom,
      quantite: _currentQuantite,
      produitRevenu: _currentProduitRevenu,
      prixUnitaire: _currentPrixUnitaire,
      benefice: _currentBenefice,
      prixTotal: prixTotal,
      beneficeTotal: beneficeTotal,
    );

    setState(() {
      _venteItems.add(newItem);
      // Réinitialiser les champs pour le prochain produit
      _resetProduitFields();
    });
  }

  void _resetProduitFields() {
    setState(() {
      _currentProduitId = null;
      _currentQuantite = 1;
      _currentProduitRevenu = 0;
      _currentPrixUnitaire = 0;
      _currentBenefice = 0;
      
      _quantiteController.text = '1';
      _produitRevenuController.text = '0';
      _prixUnitaireController.text = '0';
      _beneficeController.text = '0';
    });
  }

  void _supprimerProduit(String id) {
    setState(() {
      _venteItems.removeWhere((item) => item.id == id);
    });
  }

  double get _totalGeneral {
    return _venteItems.fold(0, (sum, item) => sum + item.prixTotal);
  }

  double get _beneficeTotal {
    return _venteItems.fold(0, (sum, item) => sum + item.beneficeTotal);
  }

  String? _validateMontantPaye(String? value) {
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
  }

  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(clientControllerProvider);
    final produitsState = ref.watch(produitControllerProvider);
    final etatsState = ref.watch(etatCommandeProvider);
    final categoriesState = ref.watch(categorieProduitControllerProvider);

    return AlertDialog(
      title: Text(widget.vente == null ? 'Nouvelle Vente' : 'Modifier Vente'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Section Informations générales
              _buildInformationsGenerales(etatsState, clientsState),
              const SizedBox(height: 20),

              // Section Ajout de produits
              _buildSectionProduits(categoriesState, produitsState),
              const SizedBox(height: 20),

              // Liste des produits ajoutés
              if (_venteItems.isNotEmpty) _buildListeProduits(),
              const SizedBox(height: 20),

              // Totaux
              _buildSectionTotaux(),
              const SizedBox(height: 16),

              // Montant payé
              _buildMontantPayeField(),
              const SizedBox(height: 16),

              // Date de vente
              _buildDateVenteField(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveVente,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _buildInformationsGenerales(AsyncValue<List<EtatCommande>> etatsState, AsyncValue<List<Client>> clientsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations générales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        
        // Client
        clientsState.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Erreur: $error'),
          data: (clients) {
            _clients = clients;
            return DropdownSearch<Client>(
              items: _clients,
              selectedItem: _clients.firstWhere(
                (c) => c.id == _clientId,
                orElse: () => Client(
                  id: '', 
                  nom: 'Sélectionner un client', 
                  entrepriseId: '', 
                  createdAt: DateTime.now(),
                  telephone: null,
                  email: null,
                  adresse: null,
                  description: null,
                  updatedAt: null,
                ),
              ),
              itemAsString: (Client c) => c.nom,
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchDelay: Duration(milliseconds: 300),
              ),
              onChanged: (Client? value) {
                setState(() {
                  _clientId = value?.id ?? '';
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

        // Description
        TextFormField(
          initialValue: _description,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _description = value),
          maxLines: 2,
        ),

        const SizedBox(height: 12),

        // État
        etatsState.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Erreur: $error'),
          data: (etats) {
            _etats = etats;
            return DropdownButtonFormField<int>(
              value: _etat,
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
                  _etat = value!;
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionProduits(AsyncValue<List<CategorieProduit>> categoriesState, AsyncValue<List<Produit>> produitsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ajouter un produit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: categoriesState.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Erreur: $error'),
                data: (categories) {
                  _categories = categories;
                  return DropdownSearch<CategorieProduit>(
                    items: _categories,
                    selectedItem: _categories.firstWhere(
                      (c) => c.id == _currentCategorieId,
                      orElse: () => CategorieProduit(
                        id: null, 
                        libelle: 'Toutes catégories', 
                        entrepriseId: '', 
                        createdAt: DateTime.now(),
                        updatedAt: null,
                      ),
                    ),
                    itemAsString: (CategorieProduit c) => c.libelle,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchDelay: Duration(milliseconds: 300),
                    ),
                    onChanged: (CategorieProduit? value) {
                      _filtrerProduitsParCategorie(value?.id);
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
            ),
            const SizedBox(width: 8),
            Expanded(
              child: produitsState.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Erreur: $error'),
                data: (produits) {
                  _produits = produits;
                  if (_produitsFiltres.isEmpty) {
                    _produitsFiltres = produits;
                  }
                  
                  return DropdownSearch<Produit>(
                    items: _produitsFiltres,
                    selectedItem: _produitsFiltres.firstWhere(
                      (p) => p.id == _currentProduitId,
                      orElse: () => Produit(
                        id: '', 
                        nom: 'Sélectionner un produit', 
                        stock: 0, 
                        prixVente: 0, 
                        prixAchat: 0,
                        defectueux: 0, 
                        entrepriseId: '', 
                        createdAt: DateTime.now(),
                        categorieId: null,
                        benefice: 0,
                        seuilAlerte: 5,
                        description: null,
                        updatedAt: null,
                      ),
                    ),
                    itemAsString: (Produit p) => '${p.nom} (Stock: ${p.stock})',
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchDelay: Duration(milliseconds: 300),
                    ),
                    onChanged: _onProduitChanged,
                    validator: (Produit? value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un produit';
                      }
                      return null;
                    },
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'Produit *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Affichage du stock disponible
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
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Stock disponible: ${produit.stock}',
                  style: TextStyle(
                    color: produit.stock < 5 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (error, stack) => const SizedBox(),
          ),

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
                onChanged: _onQuantiteChanged,
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
                onChanged: _onProduitRevenuChanged,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _prixUnitaireController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: _onPrixUnitaireChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _beneficeController,
                decoration: const InputDecoration(
                  labelText: 'Bénéfice *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: _onBeneficeChanged,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _ajouterProduit,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter ce produit'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
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
        
        ..._venteItems.map((item) => _buildProduitItem(item)).toList(),
      ],
    );
  }

  Widget _buildProduitItem(VenteItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(item.produitNom),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantité: ${item.quantite}'),
            if (item.produitRevenu > 0) Text('Revenu: ${item.produitRevenu}'),
            Text('Prix unitaire: ${item.prixUnitaire.toStringAsFixed(2)} FCFA'),
            Text('Total: ${item.prixTotal.toStringAsFixed(2)} FCFA'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _supprimerProduit(item.id),
        ),
      ),
    );
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
                const Text('Total général:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_totalGeneral.toStringAsFixed(2)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bénéfice total:'),
                Text('${_beneficeTotal.toStringAsFixed(2)} FCFA', style: const TextStyle(color: Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nombre de produits:'),
                Text('${_venteItems.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      validator: _validateMontantPaye,
      onChanged: (value) {
        setState(() {
          _montantPaye = double.tryParse(value) ?? 0;
        });
      },
    );
  }

  Widget _buildDateVenteField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dateVente,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() {
            _dateVente = date;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date de vente',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text('${_dateVente.day}/${_dateVente.month}/${_dateVente.year}'),
      ),
    );
  }

  void _saveVente() async {
    if (_formKey.currentState!.validate()) {
      if (_venteItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez ajouter au moins un produit')),
        );
        return;
      }

      if (_clientId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un client')),
        );
        return;
      }

      final venteController = ref.read(venteControllerProvider.notifier);
      final List<Vente> ventes = [];

      for (final item in _venteItems) {
        final vente = Vente(
          id: widget.vente?.id ?? _uuid.v4(),
          produitId: item.produitId,
          quantite: item.quantite,
          produitRevenu: item.produitRevenu,
          description: _description,
          prixTotal: item.prixTotal,
          prixUnitaire: item.prixUnitaire,
          etat: _etat,
          benefice: item.beneficeTotal,
          montantPaye: _montantPaye / _venteItems.length,
          dateVente: _dateVente,
          clientId: _clientId,
          userId: widget.userId,
          entrepriseId: widget.entrepriseId,
          createdAt: widget.vente?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ventes.add(vente);
      }

      try {
        if (widget.vente == null) {
          // Pour une nouvelle commande
          for (final vente in ventes) {
            await venteController.addVente(vente, widget.userId);
          }
        } else {
          // Pour la modification
          await venteController.deleteVente(widget.vente!.id, widget.userId);
          for (final vente in ventes) {
            await venteController.addVente(vente, widget.userId);
          }
        }
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}