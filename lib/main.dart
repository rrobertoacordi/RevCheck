import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tz; // ADICIONE ESTE IMPORT

import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INICIALIZA OS FUSOS HORÁRIOS PARA O AGENDAMENTO DE NOTIFICAÇÕES NÃO TRAVAR O APP
  tz.initializeTimeZones();

  await NotificationService().initNotification();
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
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('pt', 'BR')],
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
