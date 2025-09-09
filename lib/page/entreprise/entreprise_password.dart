import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project6/controller/entreprise_controller.dart';
import 'package:project6/page/home_page.dart';
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
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Icon(
                  Icons.business,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  widget.entrepriseNom,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Entrez le mot de passe pour accéder à cette entreprise',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showPassword,
                validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPassword,
                  child: _isLoading 
                    ? const CircularProgressIndicator()
                    : const Text('Accéder à l\'entreprise'),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _isLoading 
                    ? null 
                    : () => Navigator.of(context).pop(),
                child: const Text('Choisir une autre entreprise'),
              ),
            ],
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

        // Mettre l'entreprise active dans la DB
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