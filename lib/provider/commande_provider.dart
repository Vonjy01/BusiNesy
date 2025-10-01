// // lib/provider/commande_provider.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:project6/controller/command_controller.dart';
// import 'package:project6/models/command_model.dart';

// final lastPendingCommandesProvider = Provider<List<Commande>>((ref) {
//   final commandes = ref.watch(commandeControllerProvider).value ?? [];
//   return commandes
//       .where((c) => c.etat == 1)
//       .toList()
//     ..sort((a, b) => b.dateCommande.compareTo(a.dateCommande))
//     .take(10)
//     .toList();
// });

// final lastReceivedCommandesProvider = Provider<List<Commande>>((ref) {
//   final commandes = ref.watch(commandeControllerProvider).value ?? [];
//   return commandes
//       .where((c) => c.etat == 2)
//       .toList()
//     ..sort((a, b) => b.dateCommande.compareTo(a.dateCommande))
//     .take(10)
//     .toList();
// });