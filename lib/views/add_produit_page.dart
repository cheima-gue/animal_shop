import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../services/database_helper.dart';
import 'produit_list_page.dart';

class AddProduitPage extends StatefulWidget {
  @override
  _AddProduitPageState createState() => _AddProduitPageState();
}

class _AddProduitPageState extends State<AddProduitPage> {
  final _formKey = GlobalKey<FormState>();
  String nom = '';
  double prix = 0.0;
  String imagePath = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajouter un produit')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nom du produit'),
                onSaved: (value) => nom = value ?? '',
                validator: (value) => value!.isEmpty ? 'Entrez un nom' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
                onSaved: (value) => prix = double.tryParse(value!) ?? 0.0,
                validator: (value) => value!.isEmpty ? 'Entrez un prix' : null,
              ),
              TextFormField(
                decoration: InputDecoration(
                    labelText: 'Chemin de l\'image (facultatif)'),
                onSaved: (value) => imagePath = value ?? '',
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Enregistrer'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    await DatabaseHelper().insertProduit(
                      Produit(nom: nom, prix: prix, image: imagePath),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => ProduitListPage()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
