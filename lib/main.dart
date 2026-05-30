import 'package:flutter/material.dart';
import 'package:app_pp_sem_6/presentacion/pantallas/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        // fondo general de la app: beige #E6E2DC
        scaffoldBackgroundColor: const Color(0xFFE6E2DC),
      ),
      home: const Home(), // lo que se ve al abrir la app
    );
  }
}
