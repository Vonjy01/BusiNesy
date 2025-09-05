// commande_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:project6/controller/command_controller.dart';
import 'package:project6/controller/fournisseur_controller.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/controller/cat_prod_controller.dart';
import 'package:project6/models/command_model.dart';
import 'package:project6/models/etat_commande.dart';
import 'package:project6/models/fournisseur_model.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/models/categorie_produit_model.dart';
import 'package:project6/provider/etat_commande_provider.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/utils/message_text.dart';
import 'package:project6/widget/message_widget.dart';
import 'package:uuid/uuid.dart';

class CommandeDialog extends ConsumerStatefulWidget {
  final Commande? commande;
  final String userId;
  final String entrepriseId;

  const CommandeDialog({
    Key? key,
    this.commande,
    required this.userId,
    required this.entrepriseId,
  }) : super(key: key);

  @override
  ConsumerState<CommandeDialog> createState() => _CommandeDialogState();
}

class _CommandeDialogState extends ConsumerState<CommandeDialog> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();
late TextEditingController _prixController;

  late String _fournisseurId;
  late String _produitId;
  late int _quantiteCommandee;
  late int? _quantiteRecue;
  late double? _prixUnitaire;
  late DateTime _dateCommande;
  late int _etat;
  late int? _categorieId;

  List<Fournisseur> _fournisseurs = [];
  List<Produit> _produits = [];
  List<Produit> _produitsFiltres = [];
  List<EtatCommande> _etats = [];
  List<CategorieProduit> _categories = [];
@override
void initState() {
  super.initState();
  _dateCommande = DateTime.now();
  _etat = 1;
  _categorieId = null;

  _prixController = TextEditingController();

  if (widget.commande != null) {
    _fournisseurId = widget.commande!.fournisseurId;
    _produitId = widget.commande!.produitId;
    _quantiteCommandee = widget.commande!.quantiteCommandee;
    _quantiteRecue = widget.commande!.quantiteRecue;
    _prixUnitaire = widget.commande!.prixUnitaire;
    _dateCommande = widget.commande!.dateCommande;
    _etat = widget.commande!.etat;

    _prixController.text = _prixUnitaire?.toString() ?? '';

    if (_produitId.isNotEmpty) {
      _findCategorieFromProduit();
    }
  } else {
    _fournisseurId = '';
    _produitId = '';
    _quantiteCommandee = 0;
    _quantiteRecue = null;
    _prixUnitaire = null;
    _prixController.text = '';
  }
}


  double get _montantTotal {
    final quantite = (_etat == 2 || _etat == 3)
        ? (_quantiteRecue ?? _quantiteCommandee)
        : _quantiteCommandee;
    return (_prixUnitaire ?? 0) * quantite;
  }

  void _findCategorieFromProduit() {
    final produitsState = ref.read(produitControllerProvider);
    produitsState.when(
      data: (produits) {
        final produit = produits.firstWhere(
          (p) => p.id == _produitId,
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
          ),
        );
        if (produit.categorieId != null) {
          setState(() {
            _categorieId = produit.categorieId;
          });
        }
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  void _filtrerProduitsParCategorie(int? categorieId) {
    setState(() {
      _categorieId = categorieId;
      if (categorieId == null) {
        _produitsFiltres = [];
      } else {
        _produitsFiltres = _produits
            .where((produit) => produit.categorieId == categorieId)
            .toList();
      }

      // si le produit sélectionné n’appartient pas à cette catégorie → reset
      if (_produitId.isNotEmpty &&
          !_produitsFiltres.any((p) => p.id == _produitId)) {
        _produitId = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fournisseursState = ref.watch(fournisseurControllerProvider);
    final produitsState = ref.watch(produitControllerProvider);
    final etatsState = ref.watch(etatCommandeProvider);
    final categoriesState = ref.watch(categorieProduitControllerProvider);

    return AlertDialog(
      title: Text(
        widget.commande == null ? 'Nouvelle commande' : 'Modification',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: background_theme,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total : ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color_white,
                        ),
                      ),
                      Text(
                        "$_montantTotal $devise",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color_white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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

              if (_etat == 2 || _etat == 3) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _quantiteRecue?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Quantité reçue *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if ((_etat == 2 || _etat == 3) &&
                        (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.parse(value) <= 0)) {
                      return 'Veuillez entrer la quantité reçue';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _quantiteRecue = int.tryParse(value);
                  },
                ),
              ],

              const SizedBox(height: 16),

              fournisseursState.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Erreur: $error'),
                data: (fournisseurs) {
                  _fournisseurs = fournisseurs;
                  return DropdownSearch<Fournisseur>(
                    items: _fournisseurs,
                    selectedItem: _fournisseurs.firstWhere(
                      (f) => f.id == _fournisseurId,
                      orElse: () => Fournisseur(
                        id: '',
                        nom: '',
                        entrepriseId: '',
                        createdAt: DateTime.now(),
                      ),
                    ),
                    itemAsString: (Fournisseur f) => f.nom,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchDelay: Duration(milliseconds: 300),
                    ),
                    onChanged: (Fournisseur? value) {
                      setState(() {
                        _fournisseurId = value?.id ?? '';
                      });
                    },
                    validator: (Fournisseur? value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un fournisseur';
                      }
                      return null;
                    },
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'Fournisseur *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              categoriesState.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Erreur: $error'),
                data: (categories) {
                  _categories = categories;
                  return DropdownSearch<CategorieProduit>(
                    items: _categories,
                    selectedItem: _categories.firstWhere(
                      (c) => c.id == _categorieId,
                      orElse: () => CategorieProduit(
                        id: null,
                        libelle: '',
                        entrepriseId: '',
                        createdAt: DateTime.now(),
                      ),
                    ),
                    itemAsString: (CategorieProduit c) => c.libelle,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchDelay: Duration(milliseconds: 300),
                    ),
                    onChanged: (CategorieProduit? value) {
                      setState(() {
                        _categorieId = value?.id;
                      });
                      _filtrerProduitsParCategorie(value?.id);
                    },
                    validator: (CategorieProduit? value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une catégorie';
                      }
                      return null;
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

              const SizedBox(height: 16),

              produitsState.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Erreur: $error'),
                data: (produits) {
                  _produits = produits;
                  // si aucune catégorie sélectionnée → pas de produits affichés
                  if (_categorieId == null) {
                    _produitsFiltres = [];
                  } else {
                    _produitsFiltres = produits
                        .where((p) => p.categorieId == _categorieId)
                        .toList();
                  }

                  return DropdownSearch<Produit>(
                    items: _produitsFiltres,
                    selectedItem: _produitsFiltres.firstWhere(
                      (p) => p.id == _produitId,
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
                      ),
                    ),
                    itemAsString: (Produit p) => p.nom,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchDelay: Duration(milliseconds: 300),
                    ),
                    onChanged: (Produit? value) {
  setState(() {
    _produitId = value?.id ?? '';
    if (value != null) {
      _categorieId = value.categorieId;
      _prixUnitaire = value.prixAchat.toDouble();
      _prixController.text = _prixUnitaire.toString(); // met le prixAchat par défaut
    } else {
      _prixController.text = '';
      _prixUnitaire = null;
    }
  });
},

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

              const SizedBox(height: 16),

              TextFormField(
                initialValue: _quantiteCommandee.toString(),
                decoration: const InputDecoration(
                  labelText: 'Quantité commandée *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      int.tryParse(value) == null ||
                      int.parse(value) <= 0) {
                    return 'Veuillez entrer une quantité valide';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _quantiteCommandee = int.tryParse(value) ?? 0;
                  });
                },
              ),

              const SizedBox(height: 16),

           TextFormField(
  controller: _prixController,
  decoration: const InputDecoration(
    labelText: 'Prix unitaire (Optionnel)',
    border: OutlineInputBorder(),
  ),
  keyboardType: TextInputType.number,
  onChanged: (value) {
    setState(() {
      _prixUnitaire = double.tryParse(value); // reste modifiable
    });
  },
),


              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateCommande,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _dateCommande = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de commande',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_dateCommande.toString().split(' ')[0]),
                ),
              ),

              const SizedBox(height: 16),

              if (widget.commande != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _deleteCommande(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Supprimer la commande'),
                ),
              ],
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
          onPressed: _saveCommande,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  void _saveCommande() async {
    if (_formKey.currentState!.validate()) {
      final commandeController = ref.read(commandeControllerProvider.notifier);

      final commande = Commande(
        id: widget.commande?.id ?? _uuid.v4(),
        fournisseurId: _fournisseurId,
        produitId: _produitId,
        quantiteCommandee: _quantiteCommandee,
        quantiteRecue: _quantiteRecue,
        prixUnitaire: _prixUnitaire,
        dateCommande: _dateCommande,
        dateArrivee: (_etat == 2 || _etat == 3) ? DateTime.now() : null,
        etat: _etat,
        entrepriseId: widget.entrepriseId,
      );

      try {
        if (widget.commande == null) {
          await commandeController.addCommande(commande, widget.userId);
          Message.success(context, MessageText.ajoutCommandeSuccess);
        } else {
          await commandeController.updateCommande(commande, widget.userId);
          Message.success(context, MessageText.modificationCommandeSuccess);
        }
        Navigator.of(context).pop();
      } catch (e) {
        Message.error(context, "${MessageText.erreurGenerale} $e");
      }
    }
  }

  void _deleteCommande(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette commande ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final commandeController = ref.read(commandeControllerProvider.notifier);
      try {
        await commandeController.deleteCommande(widget.commande!.id);
        Message.success(context, MessageText.suppressionCommandeSuccess);
        Navigator.of(context).pop();
      } catch (e) {
        Message.error(context, "${MessageText.erreurGenerale} $e");
      }
    }
  }
}
