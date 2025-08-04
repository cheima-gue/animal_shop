import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/produit.dart';

class ProduitListPage extends StatefulWidget {
  @override
  _ProduitListPageState createState() => _ProduitListPageState();
}

class _ProduitListPageState extends State<ProduitListPage> {
  List<Produit> produits = [];
  List<Produit> filtered = [];
  final _searchController = TextEditingController();

  void fetchProduits() async {
    final data = await DatabaseHelper().getProduits();
    setState(() {
      produits = data;
      filtered = data;
    });
  }

  void filterProduits(String query) {
    final result = produits
        .where((p) => p.nom.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      filtered = result;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchProduits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Liste des produits')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: filterProduits,
              decoration: InputDecoration(
                labelText: 'Recherche',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, index) {
                final p = filtered[index];
                return ListTile(
                  leading: Icon(Icons.shopping_bag),
                  title: Text(p.nom),
                  subtitle: Text('${p.prix.toStringAsFixed(2)} DT'),
                  trailing: p.image != null && p.image!.isNotEmpty
                      ? Image.asset(p.image!,
                          width: 50,
                          height: 50,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.image_not_supported))
                      : Icon(Icons.image),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
