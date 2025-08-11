// lib/views/caisse_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../viewmodels/produit_viewmodel.dart';

class CaissePage extends StatefulWidget {
  const CaissePage({super.key});

  @override
  State<CaissePage> createState() => _CaissePageState();
}

class _CaissePageState extends State<CaissePage> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _montantRecuController = TextEditingController();
  final TextEditingController _clientIdController = TextEditingController();

  double _montantRecu = 0.0;
  double _monnaieARendre = 0.0;
  bool _isLoyalCustomer = false; // État local pour les boutons radio

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });

    _montantRecuController.addListener(_calculerMonnaie);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _barcodeController.dispose();
    _montantRecuController.removeListener(_calculerMonnaie);
    _montantRecuController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight ||
          event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight ||
          event.logicalKey == LogicalKeyboardKey.altLeft ||
          event.logicalKey == LogicalKeyboardKey.altRight) {
        return;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        final barcode = _barcodeController.text.trim();
        if (barcode.isNotEmpty) {
          Provider.of<ProduitViewModel>(context, listen: false)
              .addProductByBarcode(barcode);
          _barcodeController.clear();
        }
      } else if (event.character != null && _isDigit(event.character!)) {
        _barcodeController.text += event.character!;
      }
    }
  }

  bool _isDigit(String character) {
    return character.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
        character.codeUnitAt(0) <= '9'.codeUnitAt(0);
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

    _focusNode.unfocus();

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

    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse Enregistreuse'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _onKey,
        child: Consumer<ProduitViewModel>(
          builder: (context, produitViewModel, child) {
            final cartItems = produitViewModel.cartItems.values.toList();
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${produit.prix.toStringAsFixed(2)} DT x ${produit.quantite}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                if (produit.codeBarre != null) {
                                  produitViewModel.removeProductFromCart(
                                      produit.codeBarre!);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  // Section pour la sélection du client
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Type de client:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Passager'),
                                value: false,
                                groupValue: _isLoyalCustomer,
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    setState(() {
                                      _isLoyalCustomer = value;
                                    });
                                    produitViewModel.setIsLoyalCustomer(value);
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
                                  if (value != null) {
                                    setState(() {
                                      _isLoyalCustomer = value;
                                    });
                                    produitViewModel.setIsLoyalCustomer(value);
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
                              controller: _clientIdController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: 'Numéro de carte de fidélité',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                produitViewModel.setClientId(value);
                              },
                            ),
                          ),
                      ],
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
                            const Text('Sous-total:',
                                style: TextStyle(fontSize: 18)),
                            Text(
                                '${produitViewModel.subtotal.toStringAsFixed(2)} DT',
                                style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                        if (produitViewModel.discountAmount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Réduction (5%):',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.red)),
                              Text(
                                  '-${produitViewModel.discountAmount.toStringAsFixed(2)} DT',
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.red)),
                            ],
                          ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Text(
                                '${produitViewModel.totalPrice.toStringAsFixed(2)} DT',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal)),
                          ],
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
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('${_monnaieARendre.toStringAsFixed(2)} DT',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      produitViewModel.cartItems.clear();
                      produitViewModel
                          .setIsLoyalCustomer(false); // Réinitialiser le client
                      _clientIdController.clear();
                      produitViewModel.notifyListeners();
                      _montantRecuController.clear();
                      setState(() {
                        _montantRecu = 0.0;
                        _monnaieARendre = 0.0;
                        _isLoyalCustomer = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Paiement effectué! Panier vidé.')),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
