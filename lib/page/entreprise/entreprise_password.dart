import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/page/home_page.dart';
import 'package:project6/utils/constant.dart';
import 'package:project6/widget/logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EntreprisePasswordPage extends ConsumerStatefulWidget {
  final String entrepriseId;
  final String entrepriseNom;
  
  const EntreprisePasswordPage({
    super.key,
    required this.entrepriseId,
    required this.entrepriseNom,
  });

  @override
  ConsumerState<EntreprisePasswordPage> createState() => _EntreprisePasswordPageState();
}

class _EntreprisePasswordPageState extends ConsumerState<EntreprisePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return  Container(
      decoration: BoxDecoration(gradient: headerGradient),
      child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                     Logo(size: 80,),
                      const SizedBox(height: 24),
                      
                      // Nom de l'entreprise
                      Text(
                        widget.entrepriseNom,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: background_theme,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // Message
                      const Text(
                        'Entrez le mot de passe pour accéder à cette entreprise',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
      
                      // Champ mot de passe
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe de l\'entreprise',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) => value!.isEmpty ? 'Le mot de passe est requis' : null,
                      ),
                      const SizedBox(height: 32),
      
                      // Bouton d'accès
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: background_theme,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _isLoading ? null : _verifyPassword,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Accéder à l\'entreprise',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
      
                      // Bouton retour
                      TextButton(
                        onPressed: _isLoading 
                            ? null 
                            : () => Navigator.of(context).pop(),
                        child: const Text(
                          '← Choisir une autre entreprise',
                          style: TextStyle(
                            color: background_theme,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        
      ),
    );
  }

  Future<void> _verifyPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final isValid = await ref
          .read(entrepriseControllerProvider.notifier)
          .verifyEntreprisePassword(widget.entrepriseId, _passwordController.text);

      if (isValid) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("entrepriseId", widget.entrepriseId);
        await prefs.setString("entrepriseNom", widget.entrepriseNom);

        await ref
            .read(entrepriseControllerProvider.notifier)
            .setActiveEntreprise(widget.entrepriseId);

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mot de passe incorrect'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}