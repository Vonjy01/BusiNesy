import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/models/entreprise_model.dart';

final activeEntrepriseProvider = Provider<AsyncValue<Entreprise?>>((ref) {
  final entreprisesAsync = ref.watch(entrepriseControllerProvider);
  
  return entreprisesAsync.when(
    loading: () => const AsyncLoading<Entreprise?>(),
    error: (err, stack) => AsyncError<Entreprise?>(err, stack),
    data: (entreprises) {
      final active = entreprises.firstWhere(
        (e) => e.isActive,
        orElse: () => entreprises.isNotEmpty ? entreprises.first : throw Exception('Aucune entreprise'),
      );
      return AsyncData<Entreprise?>(active);
    },
  );
});