// page/vente/vente_group_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/vente_controller.dart';
import 'package:project6/models/vente_model.dart';
import 'package:project6/models/client_model.dart';
import 'package:project6/models/produits_model.dart';
import 'package:project6/page/vente/vente_dialog.dart';
import 'package:project6/utils/constant.dart';

class VenteGroupDetailPage extends ConsumerStatefulWidget {
  final List<Vente> ventes;
  final Client client;
  final List<Produit> produits;

  const VenteGroupDetailPage({
    Key? key,
    required this.ventes,
    required this.client,
    required this.produits,
  }) : super(key: key);

  @override
  ConsumerState<VenteGroupDetailPage> createState() => _VenteGroupDetailPageState();
}

class _VenteGroupDetailPageState extends ConsumerState<VenteGroupDetailPage> {
  bool _isMounted = true;

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.ventes.fold(0.0, (sum, v) => sum + (v.prixTotal ));
    final beneficeTotal = widget.ventes.fold(0.0, (sum, v) => sum + (v.benefice ));
    final firstVente = widget.ventes.first;

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la commande - ${widget.client.nom}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editVente(context, firstVente),
            tooltip: 'Modifier la commande',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addProductToCommand(context),
        backgroundColor: background_theme,
        child: Icon(Icons.add, color: color_white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations client
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client: ${widget.client.nom}', 
                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (widget.client.telephone != null) 
                      Text('Téléphone: ${widget.client.telephone}'),
                    if (widget.client.email != null) 
                      Text('Email: ${widget.client.email}'),
                    Text('Date: ${_formatDate(firstVente.dateVente)}'),
                    Text('État: ${_getEtatLibelle(firstVente.etat)}'),
                    Text('Nombre de produits: ${widget.ventes.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Liste des produits
            const Text('Produits commandés:', 
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: widget.ventes.length,
                itemBuilder: (context, index) {
                  final vente = widget.ventes[index];
                  final produit = widget.produits.firstWhere(
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
                      description: null,
                      updatedAt: null,
                    ),
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(produit.nom),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantité: ${vente.quantite}'),
                          if ((vente.produitRevenu ) > 0) 
                            Text('Revenu: ${vente.produitRevenu}'),
                          Text('Prix unitaire: ${(vente.prixUnitaire ).toStringAsFixed(2)} $devise'),
                          Text('Total: ${(vente.prixTotal ).toStringAsFixed(2)} $devise'),
                          Text('État: ${_getEtatLibelle(vente.etat)}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editSingleVente(context, vente),
                            tooltip: 'Modifier ce produit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _deleteSingleVente(context, vente),
                            tooltip: 'Supprimer ce produit',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Totaux
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total général:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${total.toStringAsFixed(2)} $devise', 
                             style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bénéfice total:'),
                        Text('${beneficeTotal.toStringAsFixed(2)} $devise', 
                             style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEtatLibelle(int etatId) {
    switch (etatId) {
      case 1: return 'En attente';
      case 2: return 'Validé';
      case 3: return 'Incomplet';
      case 4: return 'Annulé';
      default: return 'Inconnu';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _addProductToCommand(BuildContext context) {
    final firstVente = widget.ventes.first;
    
    showDialog(
      context: context,
      builder: (context) => VenteDialog(
        vente: Vente(
          id: '', // Nouvelle vente
          produitId: '',
          quantite: 1,
          produitRevenu: 0,
          description: firstVente.description,
          prixTotal: 0,
          prixUnitaire: 0,
          etat: firstVente.etat,
          benefice: 0,
          montantPaye: 0,
          dateVente: firstVente.dateVente,
          clientId: firstVente.clientId,
          userId: firstVente.userId,
          entrepriseId: firstVente.entrepriseId,
          createdAt: DateTime.now(),
        ),
        userId: firstVente.userId,
        entrepriseId: firstVente.entrepriseId,
      ),
    ).then((_) {
      if (_isMounted) {
        // Rafraîchir les données après ajout seulement si le widget est toujours monté
        ref.refresh(venteControllerProvider);
      }
    });
  }

  void _editVente(BuildContext context, Vente vente) {
    showDialog(
      context: context,
      builder: (context) => VenteDialog(
        vente: vente,
        userId: vente.userId,
        entrepriseId: vente.entrepriseId,
      ),
    ).then((_) {
      if (_isMounted) {
        ref.refresh(venteControllerProvider);
      }
    });
  }

  void _editSingleVente(BuildContext context, Vente vente) {
    showDialog(
      context: context,
      builder: (context) => VenteDialog(
        vente: vente,
        userId: vente.userId,
        entrepriseId: vente.entrepriseId,
      ),
    ).then((_) {
      if (_isMounted) {
        ref.refresh(venteControllerProvider);
      }
    });
  }

  void _deleteSingleVente(BuildContext context, Vente vente) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce produit de la commande ?'),
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

    if (confirm == true && _isMounted) {
      final venteController = ref.read(venteControllerProvider.notifier);
      try {
        await venteController.deleteVente(vente.id, vente.userId);
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produit supprimé de la commande')),
          );
        }
      } catch (e) {
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }
}