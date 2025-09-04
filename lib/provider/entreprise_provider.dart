import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/entreprise_model.dart';

// CHANGEZ CE PROVIDER POUR QU'IL SOIT UN FutureProvider<Entreprise?>
final activeEntrepriseProvider = FutureProvider<Entreprise?>((ref) {
  final entreprisesAsync = ref.watch(entrepriseControllerProvider);
  
  return entreprisesAsync.when(
    loading: () => null,
    error: (err, stack) => throw err,
    data: (entreprises) {
      if (entreprises.isEmpty) return null;
      
      final active = entreprises.firstWhere(
        (e) => e.isActive,
        orElse: () => entreprises.first,
      );
      
      return active;
    },
  );
});