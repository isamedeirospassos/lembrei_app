import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';

class StorageService {
  static const String _key = 'reminders';

  // Salva a lista de lembretes no celular
  static Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = reminders.map((r) => r.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_key, jsonString);
  }

  // Carrega a lista de lembretes do celular
  static Future<List<Reminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Reminder.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Limpa todos os lembretes (útil para debug)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}