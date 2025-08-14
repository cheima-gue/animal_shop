// lib/views/caisse_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../models/client.dart';

class CaissePage extends StatefulWidget {
  const CaissePage({super.key});

  @override
  State<CaissePage> createState() => _CaissePageState();
}

class _CaissePageState extends State<CaissePage> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _montantRecuController = TextEditingController();
  final TextEditingController _telController = TextEditingController();

  double _montantRecu = 0.0;
  double _monnaieARendre = 0.0;
  String _telValidationMessage = '';
  bool _isLoyalCustomer = false;

  @override
  void initState() {
    super.initState();
    _montantRecuController.addListener(_calculerMonnaie);
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _montantRecuController.removeListener(_calculerMonnaie);
    _montantRecuController.dispose();
    _telController.dispose();
    super.dispose();
  }

  void _processBarcode(String barcode) async {
    if (barcode.isNotEmpty) {
      bool success = await Provider.of<ProduitViewModel>(context, listen: false)
          .addProductByBarcode(barcode);
      _barcodeController.clear();
      FocusScope.of(context).requestFocus();

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produit avec le code-barres "$barcode" non trouvé.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calculerMonnaie() {
    final total =
        Provider.of<ProduitViewModel>(context, listen: false).totalPrice;
    final montantSaisi = double.tryParse(_montantRecuController.text) ?? 0.0;

    setState(() {
      _montantRecu = montantSaisi;
      _monnaieARendre = _montantRecu - total;
      if (_monnaieARendre < 0) {
        _monnaieARendre = 0;
      }
    });
  }

  Future<void> _showQuantityDialog(Produit produit) async {
    final TextEditingController quantiteController =
        TextEditingController(text: produit.quantite.toString());

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier la quantité de ${produit.nom}'),
          content: TextField(
            controller: quantiteController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nouvelle quantité'),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirmer'),
              onPressed: () {
                final nouvelleQuantite =
                    int.tryParse(quantiteController.text) ?? 0;
                if (nouvelleQuantite > 0) {
                  Provider.of<ProduitViewModel>(context, listen: false)
                      .updateProductQuantity(
                          produit.codeBarre!, nouvelleQuantite);
                } else {
                  Provider.of<ProduitViewModel>(context, listen: false)
                      .removeProductFromCart(produit.codeBarre!);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _validateTel(String tel) async {
    final produitViewModel =
        Provider.of<ProduitViewModel>(context, listen: false);
    if (tel.isEmpty) {
      produitViewModel.resetClient();
      setState(() {
        _telValidationMessage = '';
      });
      return;
    }

    await produitViewModel.selectClientByTel(tel);

    if (produitViewModel.selectedClient != null) {
      setState(() {
        _telValidationMessage =
            'Client: ${produitViewModel.selectedClient!.firstName} ${produitViewModel.selectedClient!.lastName}';
      });
    } else {
      setState(() {
        _telValidationMessage = 'Numéro de téléphone non trouvé.';
      });
    }
  }

  // Ajout d'une méthode pour construire le ticket de caisse
  Widget _buildTicketDeCaisse(ProduitViewModel produitViewModel) {
    final cartItems = produitViewModel.cartItems.values.toList();
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final produit = cartItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  onTap: () => _showQuantityDialog(produit),
                  leading: produit.image != null &&
                          produit.image!.isNotEmpty &&
                          File(produit.image!).existsSync()
                      ? Image.file(
                          File(produit.image!),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 50),
                  title: Text(produit.nom,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${produit.prix.toStringAsFixed(2)} DT x ${produit.quantite}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      if (produit.codeBarre != null) {
                        produitViewModel
                            .removeProductFromCart(produit.codeBarre!);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sous-total:', style: TextStyle(fontSize: 18)),
                  Text('${produitViewModel.subtotal.toStringAsFixed(2)} DT',
                      style: const TextStyle(fontSize: 18)),
                ],
              ),
              if (produitViewModel.selectedClient != null) ...[
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Points de fidélité à gagner:',
                        style: TextStyle(fontSize: 18)),
                    Text(
                        '+${produitViewModel.loyaltyPointsEarned.toStringAsFixed(2)} pts',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.blue)),
                  ],
                ),
              ],
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('${produitViewModel.totalPrice.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        TextField(
          controller: _montantRecuController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Montant reçu du client',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _calculerMonnaie(),
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Monnaie à rendre:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('${_monnaieARendre.toStringAsFixed(2)} DT',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
          ],
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            produitViewModel.finalizeOrder();
            _montantRecuController.clear();
            _telController.clear();
            setState(() {
              _montantRecu = 0.0;
              _monnaieARendre = 0.0;
              _isLoyalCustomer = false;
              _telValidationMessage = '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Paiement effectué! Points de fidélité ajoutés.')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Finaliser la commande',
              style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  // Ajout d'une méthode pour le panneau de gauche (Produits et clients)
  Widget _buildLeftPanel(ProduitViewModel produitViewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _barcodeController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Scanner ou saisir le code-barres',
              suffixIcon: Icon(Icons.qr_code_scanner),
              border: OutlineInputBorder(),
            ),
            onSubmitted: _processBarcode,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type de client:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Passager'),
                      value: false,
                      groupValue: _isLoyalCustomer,
                      onChanged: (bool? value) {
                        if (value != null && !value) {
                          setState(() {
                            _isLoyalCustomer = false;
                            _telValidationMessage = '';
                            _telController.clear();
                          });
                          produitViewModel.resetClient();
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Client'),
                      value: true,
                      groupValue: _isLoyalCustomer,
                      onChanged: (bool? value) {
                        if (value != null && value) {
                          setState(() {
                            _isLoyalCustomer = true;
                          });
                          FocusScope.of(context).requestFocus();
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_isLoyalCustomer)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: _telController,
                    keyboardType: TextInputType.phone,
                    autofocus: _isLoyalCustomer,
                    decoration: InputDecoration(
                      labelText: 'Numéro de carte de fidélité',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _validateTel(_telController.text);
                        },
                      ),
                    ),
                    onSubmitted: _validateTel,
                  ),
                ),
              if (_telValidationMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _telValidationMessage,
                    style: TextStyle(
                      color: produitViewModel.selectedClient != null
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse Enregistreuse'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Consumer<ProduitViewModel>(
        builder: (context, produitViewModel, child) {
          return Row(
            children: [
              // Panneau de gauche pour les produits et la recherche
              Expanded(
                flex: 1, // Prend la moitié de l'écran
                child: _buildLeftPanel(produitViewModel),
              ),
              // Ligne de séparation
              const VerticalDivider(width: 1),
              // Panneau de droite pour le ticket de caisse et le paiement
              Expanded(
                flex: 1, // Prend l'autre moitié de l'écran
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildTicketDeCaisse(produitViewModel),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
