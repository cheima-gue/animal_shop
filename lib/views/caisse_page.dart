// lib/views/caisse_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../models/client.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../viewmodels/client_viewmodel.dart';
import 'parametre_page.dart';
import '../services/pdf_service.dart';

class CaissePage extends StatefulWidget {
  const CaissePage({super.key});

  @override
  State<CaissePage> createState() => _CaissePageState();
}

class _CaissePageState extends State<CaissePage> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _montantRecuController = TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  double _montantRecu = 0.0;
  double _monnaieARendre = 0.0;
  bool _isLoyalCustomer = false;

  @override
  void initState() {
    super.initState();
    _montantRecuController.addListener(_calculerMonnaie);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientViewModel>(context, listen: false).fetchClients();
      Provider.of<ProduitViewModel>(context, listen: false).initialize(context);
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _montantRecuController.removeListener(_calculerMonnaie);
    _montantRecuController.dispose();
    _clientSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _processBarcode(String barcode) async {
    if (barcode.isNotEmpty) {
      bool success = await Provider.of<ProduitViewModel>(context, listen: false)
          .addProductByBarcode(barcode);
      _barcodeController.clear();
      FocusScope.of(context).requestFocus();

      if (!success) {
        final produitViewModel =
            Provider.of<ProduitViewModel>(context, listen: false);
        final produit = produitViewModel.produits.firstWhere(
          (p) => p.codeBarre == barcode,
          orElse: () => Produit(
              nom: '',
              codeBarre: '',
              prix: 0,
              subCategoryId: 0,
              quantiteEnStock: 0),
        );

        String message;
        if (produit.nom.isNotEmpty) {
          if (produit.quantiteEnStock <= 0) {
            message = 'Le produit "${produit.nom}" est en rupture de stock.';
          } else {
            message = 'Stock insuffisant pour le produit "${produit.nom}".';
          }
        } else {
          message = 'Produit avec le code-barres "$barcode" non trouvé.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
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
        TextEditingController(text: produit.quantiteEnStock.toString());
    final int maxStock = Provider.of<ProduitViewModel>(context, listen: false)
        .produits
        .firstWhere((p) => p.id == produit.id)
        .quantiteEnStock;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier la quantité de ${produit.nom}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock disponible: $maxStock'),
              const SizedBox(height: 10),
              TextField(
                controller: quantiteController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration:
                    const InputDecoration(labelText: 'Nouvelle quantité'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
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
                if (nouvelleQuantite > maxStock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'La quantité ne peut pas dépasser le stock disponible ($maxStock).'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (nouvelleQuantite > 0) {
                  Provider.of<ProduitViewModel>(context, listen: false)
                      .updateProductQuantity(produit.id!, nouvelleQuantite);
                  Navigator.of(context).pop();
                } else {
                  Provider.of<ProduitViewModel>(context, listen: false)
                      .removeProductFromCart(produit.id!);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProduitViewModel>(
      builder: (context, produitViewModel, child) {
        if (produitViewModel.produits.isEmpty) {
          return const Center(child: Text('Aucun produit n\'est disponible.'));
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: produitViewModel.produits.length,
          itemBuilder: (context, index) {
            final produit = produitViewModel.produits[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () {
                  produitViewModel.addProductByBarcode(produit.codeBarre);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: produit.image != null &&
                                  produit.image!.isNotEmpty &&
                                  File(produit.image!).existsSync()
                              ? Image.file(File(produit.image!),
                                  fit: BoxFit.cover)
                              : const Icon(Icons.image,
                                  size: 50, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        produit.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${produit.prix.toStringAsFixed(2)} DT',
                        style: const TextStyle(color: Colors.teal),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock: ${produit.quantiteEnStock}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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
                      '${produit.prix.toStringAsFixed(2)} DT x ${produit.quantiteEnStock}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      if (produit.id != null) {
                        produitViewModel.removeProductFromCart(produit.id!);
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
                // NOUVEAU: Affichage de la réduction des points de fidélité
                if (produitViewModel.loyaltyDiscount > 0) ...[
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Réduction (pts):',
                          style: TextStyle(fontSize: 18)),
                      Text(
                          '-${produitViewModel.loyaltyDiscount.toStringAsFixed(2)} DT',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.green)),
                    ],
                  ),
                ],
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
        // NOUVEAU: Bouton pour utiliser les points de fidélité
        if (produitViewModel.selectedClient != null &&
            produitViewModel.selectedClient!.loyaltyPoints > 0)
          ElevatedButton(
            onPressed: produitViewModel.loyaltyDiscount == 0
                ? () {
                    produitViewModel.applyLoyaltyPoints();
                    _calculerMonnaie();
                  }
                : null, // Désactive le bouton si la réduction est déjà appliquée
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              produitViewModel.loyaltyDiscount > 0
                  ? 'Réduction appliquée!'
                  : 'Utiliser les points de fidélité (${produitViewModel.selectedClient!.loyaltyPoints.toStringAsFixed(2)} pts)',
              style: const TextStyle(fontSize: 18),
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
            final produitViewModel =
                Provider.of<ProduitViewModel>(context, listen: false);
            final total = produitViewModel.totalPrice;

            if (total == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Le panier est vide.'),
                  backgroundColor: Colors.orange,
                ),
              );
            } else if (_montantRecu >= total) {
              produitViewModel.finalizeOrder();

              PdfService().generateAndPrintTicketPdf(
                produitViewModel,
                _montantRecu,
                _monnaieARendre,
              );

              _montantRecuController.clear();
              setState(() {
                _montantRecu = 0.0;
                _monnaieARendre = 0.0;
                _isLoyalCustomer = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paiement effectué!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Le montant reçu est insuffisant pour finaliser la commande.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
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

  Widget _buildClientPanel(
      ClientViewModel clientViewModel, ProduitViewModel produitViewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _clientSearchController,
            decoration: const InputDecoration(
              labelText: 'Rechercher un client',
              suffixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (query) {
              clientViewModel.searchClients(query);
            },
          ),
        ),
        if (produitViewModel.selectedClient != null)
          _buildSelectedClientDetails(produitViewModel),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: clientViewModel.filteredClients.length,
            itemBuilder: (context, index) {
              final client = clientViewModel.filteredClients[index];
              return ListTile(
                title: Text('${client.firstName} ${client.lastName}'),
                subtitle: Text('Tél: ${client.tel}'),
                trailing:
                    Text('${client.loyaltyPoints.toStringAsFixed(2)} pts'),
                onTap: () {
                  produitViewModel.selectClient(client);
                },
                selected: produitViewModel.selectedClient?.id == client.id,
                selectedTileColor: Colors.teal.withOpacity(0.1),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedClientDetails(ProduitViewModel produitViewModel) {
    final client = produitViewModel.selectedClient!;
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Client sélectionné:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text('${client.firstName} ${client.lastName}',
              style: const TextStyle(fontSize: 16)),
          Text('Tél: ${client.tel}', style: const TextStyle(fontSize: 16)),
          Text('Points de fidélité: ${client.loyaltyPoints.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse Enregistreuse'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ParametrePage()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
                const SizedBox(height: 10),
                Expanded(
                  child: _buildProductGrid(),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 1,
            child: Consumer2<ProduitViewModel, ClientViewModel>(
              builder: (context, produitViewModel, clientViewModel, child) {
                return Column(
                  children: [
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
                                  _clientSearchController.clear();
                                  produitViewModel.resetClient();
                                });
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
                                  clientViewModel.fetchClients();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_isLoyalCustomer)
                      Expanded(
                        child: _buildClientPanel(
                            clientViewModel, produitViewModel),
                      )
                    else
                      const Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Ajouter des produits pour un client passager.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 1,
            child: Consumer<ProduitViewModel>(
              builder: (context, produitViewModel, child) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildTicketDeCaisse(produitViewModel),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
