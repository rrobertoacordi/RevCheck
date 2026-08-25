import 'package:flutter/material.dart';

class AppTheme {
  // Notificador do modo (Escuro / Claro)
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );

  // Notificador da cor principal do app (Padrão: Azul)
  static final ValueNotifier<Color> primaryColor = ValueNotifier(Colors.blue);

  static void alternarTema(bool isDark) {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static void mudarCor(Color novaCor) {
    primaryColor.value = novaCor;
  }
}
