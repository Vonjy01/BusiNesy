// providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/produit_controller.dart';
import 'package:project6/models/produits_model.dart';

// Provider pour accéder à tous les produits
final allProduitsProvider = Provider<List<Produit>>((ref) {
  final produitsState = ref.watch(produitControllerProvider);
  return produitsState.value ?? [];
});

// Provider pour filtrer les produits par catégorie
final produitsByCategorieProvider = Provider.family<List<Produit>, int?>((ref, categorieId) {
  final produits = ref.watch(allProduitsProvider);
  if (categorieId == null) return produits;
  return produits.where((p) => p.categorieId == categorieId).toList();
});

// Provider pour les produits en stock bas
final lowStockProduitsProvider = Provider<List<Produit>>((ref) {
  final produits = ref.watch(allProduitsProvider);
  return produits.where((p) => p.stockDisponible > 0 && p.stockDisponible <= p.seuilAlerte).toList();
});

// Provider pour les produits épuisés
final outOfStockProduitsProvider = Provider<List<Produit>>((ref) {
  final produits = ref.watch(allProduitsProvider);
  return produits.where((p) => p.stockDisponible <= 0).toList();
});

// Provider pour les produits défectueux
final defectiveProduitsProvider = Provider<List<Produit>>((ref) {
  final produits = ref.watch(allProduitsProvider);
  return produits.where((p) => p.defectueux > 0).toList();
});