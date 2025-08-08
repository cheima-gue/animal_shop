import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

  double _montantRecu = 0.0;
  double _monnaieARendre = 0.0;

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
    super.dispose();
  }

  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Ignore modifier keys to prevent assertion errors.
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight ||
          event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight ||
          event.logicalKey == LogicalKeyboardKey.altLeft ||
          event.logicalKey == LogicalKeyboardKey.altRight) {
        return; // Ignore these key presses
      }

      // The scanner's input ends with the 'Enter' key.
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        final barcode = _barcodeController.text.trim();
        if (barcode.isNotEmpty) {
          Provider.of<ProduitViewModel>(context, listen: false)
              .addProductByBarcode(barcode);
          _barcodeController.clear();
        }
      } else if (event.character != null && _isDigit(event.character!)) {
        // We only add digits to the barcode controller.
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
                            trailing: Text(
                                '${(produit.prix * produit.quantite).toStringAsFixed(2)} DT',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
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
                      produitViewModel.notifyListeners();
                      _montantRecuController.clear();
                      setState(() {
                        _montantRecu = 0.0;
                        _monnaieARendre = 0.0;
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
