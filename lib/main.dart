// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_helper.dart';
import 'viewmodels/produit_viewmodel.dart';
import 'viewmodels/client_viewmodel.dart';
import 'viewmodels/parametre_viewmodel.dart';
import 'viewmodels/category_viewmodel.dart'; // Importer le CategoryViewModel
import 'views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProduitViewModel()),
        ChangeNotifierProvider(create: (_) => ClientViewModel()),
        ChangeNotifierProvider(create: (_) => ParametreViewModel()),
        ChangeNotifierProvider(
            create: (_) =>
                CategoryViewModel()), // Ajouter le CategoryViewModel ici
      ],
      child: MaterialApp(
        title: 'POS App',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
