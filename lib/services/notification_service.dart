import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

typedef OnConcluidoCallback = void Function(int id);
OnConcluidoCallback? onConcluidoGlobal;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ══════════════════════════════════════════════════════════
  //  INICIALIZAR
  // ══════════════════════════════════════════════════════════
  Future<void> inicializar() async {
    tz_data.initializeTimeZones();

    final AndroidNotificationChannel canal = AndroidNotificationChannel(
      'lembrei_canal',
      'Lembretes',
      description: 'Notificações do app Lembrei',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(canal);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    // ✅ PEDE PERMISSÃO DE NOTIFICAÇÃO (Android 13+)
    await androidImpl?.requestNotificationsPermission();

    // ✅ PEDE PERMISSÃO DE ALARME EXATO (Android 12+)
    await androidImpl?.requestExactAlarmsPermission();
  }

  // ══════════════════════════════════════════════════════════
  //  RESPOSTA — FOREGROUND (app aberto)
  // ══════════════════════════════════════════════════════════
  static void _onNotificationResponse(NotificationResponse response) async {
    if (response.actionId == 'concluir_action') {
      final id = response.id ?? 0;
      await _marcarConcluido(id);
      onConcluidoGlobal?.call(id);
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  // ══════════════════════════════════════════════════════════
  //  RESPOSTA — BACKGROUND (app fechado)
  // ══════════════════════════════════════════════════════════
  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse response) async {
    if (response.actionId == 'concluir_action') {
      final id = response.id ?? 0;
      await _marcarConcluido(id);
      onConcluidoGlobal?.call(id);
    }
  }

  // ══════════════════════════════════════════════════════════
  //  MARCAR COMO CONCLUÍDO
  // ══════════════════════════════════════════════════════════
  static Future<void> _marcarConcluido(int notifId) async {
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString('lembretes');
    if (dados == null) return;

    final lembretes = (jsonDecode(dados) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    bool encontrou = false;

    for (var lembrete in lembretes) {
      final lembreteId = lembrete['id'] as int? ?? -1;
      final dias = List<String>.from(lembrete['dias'] ?? []);

      // lembrete sem dias (data específica ou único) → ID exato
      if (dias.isEmpty && lembreteId == notifId) {
        lembrete['concluido']       = true;
        lembrete['ultimaConclusao'] = DateTime.now().toIso8601String();
        encontrou = true;
        break;
      }

      // lembrete recorrente por dias → ID base + índice do dia
      if (dias.isNotEmpty) {
        for (int i = 0; i < dias.length; i++) {
          if (lembreteId + i == notifId) {
            lembrete['concluido']       = true;
            lembrete['ultimaConclusao'] = DateTime.now().toIso8601String();
            encontrou = true;
            break;
          }
        }
      }

      if (encontrou) break;
    }

    await prefs.setString('lembretes', jsonEncode(lembretes));
  }

  // ══════════════════════════════════════════════════════════
  //  AGENDAR NOTIFICAÇÃO
  // ══════════════════════════════════════════════════════════
  Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required int hora,
    required int minuto,
    required List<String> dias,
    DateTime? dataEspecifica,    // ← data única (feature 2)
    String prioridade = 'Média', // ← Baixa | Média | Alta (feature 3)
  }) async {

    // ── prefixo de prioridade no título ───────────────────
    final String prefixo = switch (prioridade) {
      'Alta'  => '🔴 ',
      'Média' => '🟡 ',
      'Baixa' => '🟢 ',
      _       => '',
    };
    final String tituloFinal = '$prefixo$titulo';

    // ── ação "concluir" ───────────────────────────────────
    const AndroidNotificationAction acaoConcluir = AndroidNotificationAction(
      'concluir_action',
      '✅ CONCLUIR',
      cancelNotification: true,
      showsUserInterface: true,
    );

    // ── detalhes base ─────────────────────────────────────
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'lembrei_canal',
      'Lembretes',
      channelDescription: 'Notificações do app Lembrei',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      actions: [acaoConcluir],
      styleInformation: BigTextStyleInformation(corpo),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      // cor da notificação conforme prioridade
      color: switch (prioridade) {
        'Alta'  => const Color(0xFFE53935), // vermelho
        'Média' => const Color(0xFFFB8C00), // laranja
        'Baixa' => const Color(0xFF43A047), // verde
        _       => const Color(0xFF424242), // cinza
      },
    );

    final NotificationDetails detalhes =
        NotificationDetails(android: androidDetails);

    // ══════════════════════════════════════════════════════
    //  CASO 1 — DATA ESPECÍFICA (lembrete único)
    // ══════════════════════════════════════════════════════
    if (dataEspecifica != null) {
      final dataHora = DateTime(
        dataEspecifica.year,
        dataEspecifica.month,
        dataEspecifica.day,
        hora,
        minuto,
      );

      // se a data/hora já passou, não agenda
      if (dataHora.isBefore(DateTime.now())) return;

      await _plugin.zonedSchedule(
        id,
        tituloFinal,
        corpo,
        tz.TZDateTime.from(dataHora, tz.local),
        detalhes,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return;
    }

    // ══════════════════════════════════════════════════════
    //  CASO 2 — SEM DIAS (dispara apenas hoje / próximo dia)
    // ══════════════════════════════════════════════════════
    if (dias.isEmpty) {
      final agora = DateTime.now();
      var dataHora =
          DateTime(agora.year, agora.month, agora.day, hora, minuto);
      if (dataHora.isBefore(agora)) {
        dataHora = dataHora.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id,
        tituloFinal,
        corpo,
        tz.TZDateTime.from(dataHora, tz.local),
        detalhes,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return;
    }

    // ══════════════════════════════════════════════════════
    //  CASO 3 — DIAS DA SEMANA (recorrente)
    // ══════════════════════════════════════════════════════
    for (int i = 0; i < dias.length; i++) {
      final diaSemana = _diaParaInt(dias[i]);
      if (diaSemana == null) continue;

      await _plugin.zonedSchedule(
        id + i,
        tituloFinal,
        corpo,
        _proximoDiaSemana(hora, minuto, diaSemana),
        detalhes,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  // ══════════════════════════════════════════════════════════
  //  CANCELAR NOTIFICAÇÃO
  // ══════════════════════════════════════════════════════════
  Future<void> cancelarNotificacao(int id) async {
    await _plugin.cancel(id);
    // cancela também os IDs dos dias (id+1 até id+6)
    for (int i = 1; i < 7; i++) {
      await _plugin.cancel(id + i);
    }
  }

  // ══════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════
  tz.TZDateTime _proximoDiaSemana(int hora, int minuto, int diaSemana) {
    final tz.TZDateTime agora = tz.TZDateTime.now(tz.local);
    tz.TZDateTime dataHora = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day,
      hora,
      minuto,
    );

    while (dataHora.weekday != diaSemana || dataHora.isBefore(agora)) {
      dataHora = dataHora.add(const Duration(days: 1));
    }
    return dataHora;
  }

  int? _diaParaInt(String dia) {
    switch (dia.toLowerCase()) {
      case 'seg':
        return DateTime.monday;
      case 'ter':
        return DateTime.tuesday;
      case 'qua':
        return DateTime.wednesday;
      case 'qui':
        return DateTime.thursday;
      case 'sex':
        return DateTime.friday;
      case 'sab':
      case 'sáb':
        return DateTime.saturday;
      case 'dom':
        return DateTime.sunday;
      default:
        return null;
    }
  }
}