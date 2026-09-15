import 'package:flutter/material.dart';

import 'data/app_data.dart';
import 'screens/examenes_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppData.instancia.abrir();
  runApp(const OpositoraGumyApp());
}

class OpositoraGumyApp extends StatelessWidget {
  const OpositoraGumyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpositoraGumy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3949AB)),
      ),
      home: const ExamenesScreen(),
    );
  }
}
