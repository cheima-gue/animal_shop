import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../viewmodels/produit_viewmodel.dart';
import '../models/client.dart';
import 'database_helper.dart';

class PdfService {
  Future<void> generateAndPrintTicketPdf(ProduitViewModel produitViewModel,
      double montantRecu, double monnaieARendre) async {
    final doc = pw.Document();

    final cartItems = produitViewModel.cartItems.values.toList();
    final client = produitViewModel.selectedClient;
    final total = produitViewModel.totalPrice;
    final subtotal = produitViewModel.subtotal;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Format de rouleau de caisse
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'CHICO PETS', // Nom de votre entreprise
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 18),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'EL GHAZELA',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'TEL: 56 084 084',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Date: ${DateTime.now().toString().substring(0, 16)}'),
              if (client != null) ...[
                pw.SizedBox(height: 5),
                pw.Text('Client: ${client.firstName} ${client.lastName}'),
                if (client.loyaltyPoints > 0)
                  pw.Text('Points: ${client.loyaltyPoints.toStringAsFixed(2)}'),
              ],
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Article',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Prix U.',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Montant',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(),
              ...cartItems.map((produit) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                          '${produit.quantiteEnStock} x ${produit.nom}'),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text('${produit.prix.toStringAsFixed(2)} DT'),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        '${(produit.prix * produit.quantiteEnStock).toStringAsFixed(2)} DT',
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                );
              }),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Sous-total:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${subtotal.toStringAsFixed(2)} DT'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${total.toStringAsFixed(2)} DT'),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ESPÈCES:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${montantRecu.toStringAsFixed(2)} DT'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('RENDU:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${monnaieARendre.toStringAsFixed(2)} DT'),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Merci pour votre visite',
                    style: const pw.TextStyle(fontSize: 14)),
              ),
              pw.Center(
                child: pw.Text('À bientôt',
                    style: const pw.TextStyle(fontSize: 14)),
              ),
            ],
          );
        },
      ),
    );

    // Partager le PDF
    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'ticket_de_caisse.pdf');
  }
}
