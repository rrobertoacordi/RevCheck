import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme_notifier.dart';

void main() {
  runApp(const RevCheckApp());
}

class RevCheckApp extends StatelessWidget {
  const RevCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: AppTheme.primaryColor,
          builder: (context, currentColor, _) {
            return MaterialApp(
              title: 'RevCheck',
              debugShowCheckedModeBanner: false,
              themeMode: currentMode,
              theme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: currentColor,
                brightness: Brightness.light,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: currentColor,
                brightness: Brightness.dark,
              ),
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
