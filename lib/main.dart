import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/produit_viewmodel.dart';
import 'views/home_page.dart';

void main() {
  runApp(
    // Assurez-vous que le ChangeNotifierProvider englobe MyApp
    ChangeNotifierProvider(
      create: (context) => ProduitViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Produits',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        // Configurer la barre d'application pour qu'elle corresponde au thème
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal, // Couleur de l'AppBar
          foregroundColor: Colors.white, // Couleur du texte/icônes de l'AppBar
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
