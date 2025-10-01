import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/page/vente/vente_item.dart';

final venteItemsProvider = StateNotifierProvider<VenteItemsNotifier, List<VenteItem>>((ref) {
  return VenteItemsNotifier();
});

class VenteItemsNotifier extends StateNotifier<List<VenteItem>> {
  VenteItemsNotifier() : super([]);

  void ajouterProduit(VenteItem item) {
    state = [...state, item]..sort((a, b) => a.produitNom.compareTo(b.produitNom));
  }

  void supprimerProduit(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void modifierProduit(VenteItem updatedItem) {
    state = state.map((item) => item.id == updatedItem.id ? updatedItem : item).toList()
      ..sort((a, b) => a.produitNom.compareTo(b.produitNom));
  }
}