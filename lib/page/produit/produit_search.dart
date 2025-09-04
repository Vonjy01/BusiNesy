import 'package:flutter/material.dart';
import 'package:project6/models/produits_model.dart';

class ProduitSearchDialog extends StatefulWidget {
  final List<Produit> produits;
  final List<String> categories; // Ce sont déjà les libellés
  final Function(String, String) onSearch;

  const ProduitSearchDialog({
    super.key,
    required this.produits,
    required this.categories,
    required this.onSearch,
  });

  @override
  State<ProduitSearchDialog> createState() => _ProduitSearchDialogState();
}

class _ProduitSearchDialogState extends State<ProduitSearchDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCategory;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.isNotEmpty ? widget.categories.first : 'Toutes';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Recherche avancée',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du produit',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: widget.categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitSearch,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Rechercher'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitSearch() {
    widget.onSearch(
      _nameController.text.trim(),
      _selectedCategory == 'Toutes' ? '' : _selectedCategory,
    );
    Navigator.pop(context);
  }
}