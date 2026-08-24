import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const RevCheckApp());
}

class RevCheckApp extends StatelessWidget {
  const RevCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RevCheck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
