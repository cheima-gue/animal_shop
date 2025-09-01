// lib/screens/caisse_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../viewmodels/client_viewmodel.dart';
import '../viewmodels/parametre_viewmodel.dart';
import '../viewmodels/commande_viewmodel.dart';
import 'parametre_page.dart';
import 'client_list_page.dart';
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
  final TextEditingController _loyaltyPointsController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  double _montantRecu = 0.0;
  double _monnaieARendre = 0.0;
  bool _isLoyalCustomer = false;
  double _pointsInDinars = 0.0;

  @override
  void initState() {
    super.initState();
    _montantRecuController.addListener(_calculerMonnaie);
    _loyaltyPointsController.addListener(_updateLoyaltyDiscount);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientViewModel>(context, listen: false).fetchClients();
      Provider.of<ProduitViewModel>(context, listen: false).fetchProduits();
      Provider.of<ParametreViewModel>(context, listen: false).fetchParametres();
      _calculerMonnaie();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _montantRecuController.removeListener(_calculerMonnaie);
    _montantRecuController.dispose();
    _clientSearchController.dispose();
    _loyaltyPointsController.removeListener(_updateLoyaltyDiscount);
    _loyaltyPointsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateLoyaltyDiscount() {
    final commandeViewModel =
        Provider.of<CommandeViewModel>(context, listen: false);
    final pointsToUse = double.tryParse(_loyaltyPointsController.text) ?? 0.0;
    commandeViewModel.applyLoyaltyPoints(pointsToUse);
    _calculerMonnaie();
  }

  void _calculatePointsInDinars(double points) {
    final parametre =
        Provider.of<ParametreViewModel>(context, listen: false).parametre;
    if (parametre != null) {
      final double valeurDinar = parametre.valeurDinar;
      final double pointsParDinar = parametre.pointsParDinar;
      if (pointsParDinar > 0) {
        setState(() {
          _pointsInDinars = (points / pointsParDinar) * valeurDinar;
        });
      } else {
        setState(() {
          _pointsInDinars = 0.0;
        });
      }
    }
  }

  void _processBarcode(String barcode) async {
    if (barcode.isNotEmpty) {
      final produitViewModel =
          Provider.of<ProduitViewModel>(context, listen: false);
      final commandeViewModel =
          Provider.of<CommandeViewModel>(context, listen: false);

      final produit = await produitViewModel.getProduitByCodeBarre(barcode);

      _barcodeController.clear();
      FocusScope.of(context).requestFocus();

      if (produit != null) {
        if (produit.quantiteEnStock > 0) {
          commandeViewModel.addProductByBarcode(produit);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Le produit "${produit.nom}" est en rupture de stock.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
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
    final total = Provider.of<CommandeViewModel>(context, listen: false).total;
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

    final produitEnStock =
        await Provider.of<ProduitViewModel>(context, listen: false)
            .getProduitByCodeBarre(produit.codeBarre);
    final int maxStock = produitEnStock?.quantiteEnStock ?? 0;

    final commandeViewModel =
        Provider.of<CommandeViewModel>(context, listen: false);

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
                  commandeViewModel.updateProductQuantity(
                      produit.id!, nouvelleQuantite);
                  Navigator.of(context).pop();
                } else {
                  commandeViewModel.removeProductFromCart(produit.id!);
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
                onTap: () => _processBarcode(produit.codeBarre),
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

  Widget _buildTicketDeCaisse(CommandeViewModel commandeViewModel) {
    final cartItems = commandeViewModel.cartItems.values.toList();
    final parametre = Provider.of<ParametreViewModel>(context).parametre;

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
                        commandeViewModel.removeProductFromCart(produit.id!);
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
                  Text('${commandeViewModel.subtotal.toStringAsFixed(2)} DT',
                      style: const TextStyle(fontSize: 18)),
                ],
              ),
              if (commandeViewModel.selectedClient != null &&
                  parametre != null) ...[
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Points de fidélité à gagner:',
                        style: TextStyle(fontSize: 18)),
                    Text(
                        '+${commandeViewModel.loyaltyPointsEarned.toStringAsFixed(2)} pts',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.blue)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Points de fidélité du client:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${commandeViewModel.selectedClient!.loyaltyPoints.toStringAsFixed(2)} pts',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_pointsInDinars > 0)
                      Text(
                        '(${_pointsInDinars.toStringAsFixed(2)} DT)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _loyaltyPointsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Points à utiliser',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final pointsToUse = double.tryParse(
                                    _loyaltyPointsController.text) ??
                                0.0;
                            commandeViewModel.applyLoyaltyPoints(pointsToUse);
                            _calculerMonnaie();
                          },
                          child: const Text('Appliquer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (commandeViewModel.loyaltyDiscount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Réduction (points):'),
                          Text(
                              '-${commandeViewModel.loyaltyDiscount.toStringAsFixed(2)} DT'),
                        ],
                      ),
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
                  Text('${commandeViewModel.total.toStringAsFixed(2)} DT',
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
          onPressed: () async {
            final commandeViewModel =
                Provider.of<CommandeViewModel>(context, listen: false);
            final total = commandeViewModel.total;

            if (total == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Le panier est vide.'),
                  backgroundColor: Colors.orange,
                ),
              );
            } else if (_montantRecu >= total) {
              final double pointsEarned = commandeViewModel.loyaltyPointsEarned;
              final double pointsUsed = commandeViewModel.loyaltyPointsUsed;
              final double clientInitialPoints =
                  commandeViewModel.selectedClient?.loyaltyPoints ?? 0;
              final double newLoyaltyPoints =
                  clientInitialPoints + pointsEarned - pointsUsed;

              await commandeViewModel.finalizeOrder();

              await PdfService().generateAndPrintTicketPdf(
                commandeViewModel,
                _montantRecu,
                _monnaieARendre,
                newLoyaltyPoints,
              );

              _montantRecuController.clear();
              _loyaltyPointsController.clear();
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
      ClientViewModel clientViewModel, CommandeViewModel commandeViewModel) {
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
        if (commandeViewModel.selectedClient != null)
          _buildSelectedClientDetails(commandeViewModel),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: clientViewModel.filteredClients.length,
            itemBuilder: (context, index) {
              final client = clientViewModel.filteredClients[index];
              return ListTile(
                title: Text('${client.firstName} ${client.lastName}'),
                subtitle: Text('Tél: ${client.tel}'),
                trailing: Text(
                    '${client.loyaltyPoints.toStringAsFixed(2) ?? '0.00'} pts'),
                onTap: () {
                  commandeViewModel.selectClient(client);
                  _calculatePointsInDinars(client.loyaltyPoints);
                  _loyaltyPointsController.text =
                      client.loyaltyPoints.toStringAsFixed(2);
                },
                selected: commandeViewModel.selectedClient?.id == client.id,
                selectedTileColor: Colors.teal.withOpacity(0.1),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedClientDetails(CommandeViewModel commandeViewModel) {
    final client = commandeViewModel.selectedClient!;
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
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ClientListPage()),
              );
            },
          ),
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
            child: Consumer2<CommandeViewModel, ClientViewModel>(
              builder: (context, commandeViewModel, clientViewModel, child) {
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
                                  commandeViewModel.resetClient();
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
                            clientViewModel, commandeViewModel),
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
            child: Consumer<CommandeViewModel>(
              builder: (context, commandeViewModel, child) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildTicketDeCaisse(commandeViewModel),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
