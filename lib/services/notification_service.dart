import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> agendarNotificacaoEquipamento({
    required int id,
    required String nomeEquipamento,
    required DateTime dataHora,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'revcheck_lembretes',
          'Lembretes de Revisão',
          channelDescription:
              'Notificações para lembrete de revisão de equipamentos',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Converte a data selecionada para o formato do TimeZone local
    final scheduledDate = tz.TZDateTime.from(dataHora, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, // ID único da notificação (pode usar o ID do equipamento)
      'Lembrete de Revisão!',
      'O equipamento "$nomeEquipamento" está na hora de revisar! Verifique os componentes!',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelarNotificacao(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
