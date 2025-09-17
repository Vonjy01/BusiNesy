
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/auth_controller.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/controller/etat_commande.dart';
import 'package:project6/page/auth/login_page.dart';
import 'package:project6/page/entreprise/entreprise_selection.dart';
import 'package:project6/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
    final container = ProviderContainer();
  await container.read(etatCommandeControllerProvider.future);
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
      // Ajoutez cette configuration pour les routes nommées
      routes: {
        '/login': (context) => const LoginScreen(),
        '/entreprise-selection': (context) => const EntrepriseSelectionPage(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => const LoginScreen(),
      data: (user) {
        if (user == null) return const LoginScreen();
        
        // TOUJOURS rediriger vers la sélection d'entreprise après connexion
        return const EntrepriseSelectionPage();
      },
    );
  }
}