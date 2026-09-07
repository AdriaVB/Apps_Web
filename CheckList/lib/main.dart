import 'package:flutter/material.dart';

import 'data/app_data.dart';
import 'screens/listas_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppData.instancia.abrir();
  runApp(const CheckListApp());
}

class CheckListApp extends StatelessWidget {
  const CheckListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckList',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const ListasScreen(),
    );
  }
}
