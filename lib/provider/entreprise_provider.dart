import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/entreprise_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// CHANGEZ CE PROVIDER POUR QU'IL SOIT UN FutureProvider<Entreprise?>
// final activeEntrepriseProvider = FutureProvider<Entreprise?>((ref) {
//   final entreprisesAsync = ref.watch(entrepriseControllerProvider);
  
//   return entreprisesAsync.when(
//     loading: () => null,
//     error: (err, stack) => throw err,
//     data: (entreprises) {
//       if (entreprises.isEmpty) return null;
      
//       final active = entreprises.firstWhere(
//         (e) => e.isActive,
//         orElse: () => entreprises.first,
//       );
      
//       return active;
//     },
//   );
// });
final activeEntrepriseProvider = FutureProvider<Entreprise?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final entrepriseId = prefs.getString("entrepriseId");

  final entreprises = await ref.watch(entrepriseControllerProvider.future);

  if (entreprises.isEmpty) return null;

  if (entrepriseId != null) {
    final active = entreprises.firstWhere(
      (e) => e.id == entrepriseId,
      orElse: () => entreprises.first,
    );
    return active;
  }

  return null; // Retourner null si aucune entreprise n'est sélectionnée
});