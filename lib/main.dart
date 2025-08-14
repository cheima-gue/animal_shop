// lib/main.dart

import 'package:flutter/material.dart';
import 'package:my_desktop_app/viewmodels/client_viewmodel.dart';
import 'package:provider/provider.dart';
import 'views/home_page.dart';
import 'viewmodels/produit_viewmodel.dart';
import 'viewmodels/category_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProduitViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(
            create: (_) => ClientViewModel()), // Ajoutez le ClientViewModel ici
      ],
      child: MaterialApp(
        title: 'My Desktop App',
        theme: ThemeData(
          primaryColor: Colors.teal,
          scaffoldBackgroundColor: Colors.grey[200],
          cardColor: Colors.white,
          appBarTheme: const AppBarTheme(
            color: Colors.teal,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.teal, width: 2.0),
            ),
          ),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
