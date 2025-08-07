import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/page/auth/login_page.dart';
import 'package:project6/page/home_page.dart';
import 'package:project6/page/nouveau_entreprise.dart';
import 'package:project6/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  // Initialisation de la base de données
  await DatabaseHelper.instance.database;
  await DatabaseHelper.instance.debugDatabase();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Stock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final entreprisesState = ref.watch(entrepriseControllerProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => const LoginScreen(),
      data: (user) {
        if (user == null) return const LoginScreen();
        
        return entreprisesState.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) =>  NouveauEntreprise(),
          data: (entreprises) {
            // Vérifier si l'utilisateur a au moins une entreprise
            final userEntreprises = entreprises.where((e) => e.userId == user.id).toList();
            return userEntreprises.isNotEmpty ? const HomePage() :  NouveauEntreprise();
          },
        );
      },
    );
  }
}