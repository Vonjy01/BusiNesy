// utils/vente_grouper.dart
import 'package:project6/models/vente_model.dart';

class VenteGrouper {
  static Map<String, List<Vente>> groupByClientAndDate(List<Vente> ventes) {
    final grouped = <String, List<Vente>>{};
    
    for (final vente in ventes) {
      if (vente.clientId != null) {
        final dateKey = '${vente.dateVente.year}-${vente.dateVente.month}-${vente.dateVente.day}';
        final key = '${vente.clientId}-$dateKey-${vente.dateVente.hour}-${vente.dateVente.minute}';
        
        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(vente);
      }
    }
    
    return grouped;
  }

  static Map<String, List<Vente>> groupByClient(List<Vente> ventes) {
    final grouped = <String, List<Vente>>{};
    
    for (final vente in ventes) {
      if (vente.clientId != null) {
        if (!grouped.containsKey(vente.clientId)) {
          grouped[vente.clientId!] = [];
        }
        grouped[vente.clientId!]!.add(vente);
      }
    }
    
    return grouped;
  }
}