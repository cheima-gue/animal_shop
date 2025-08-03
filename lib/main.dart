// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/produit_viewmodel.dart';
import 'views/produit_home_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProduitViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MVVM Produits',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProduitHomePage(),
    );
  }
}
