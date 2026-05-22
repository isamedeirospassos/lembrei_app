import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder.dart';
import 'device_service.dart';

class StorageService {
  static final _supabase = Supabase.instance.client;
  static const String _tabela = 'lembretes';

  // ============================================
  // 💾 SALVAR lista completa (sincroniza tudo)
  // ============================================
  static Future<void> saveReminders(List<Reminder> reminders) async {
    try {
      final deviceId = await DeviceService.getDeviceId();

      // Pra cada lembrete, faz um upsert (insere se não existe, atualiza se existe)
      for (final reminder in reminders) {
        final dados = reminder.toSupabase();
        dados['device_id'] = deviceId;

        await _supabase.from(_tabela).upsert(dados);
      }

      print('✅ ${reminders.length} lembretes sincronizados');
    } catch (e) {
      print('❌ Erro ao salvar lembretes: $e');
    }
  }

  // ============================================
  // 📋 CARREGAR todos os lembretes do dispositivo
  // ============================================
  static Future<List<Reminder>> loadReminders() async {
    try {
      final deviceId = await DeviceService.getDeviceId();

      final response = await _supabase
          .from(_tabela)
          .select()
          .eq('device_id', deviceId)
          .order('data_hora', ascending: true);

      final lembretes = (response as List)
          .map((json) => Reminder.fromSupabase(json))
          .toList();

      print('📋 ${lembretes.length} lembretes carregados da nuvem');
      return lembretes;
    } catch (e) {
      print('❌ Erro ao carregar lembretes: $e');
      return [];
    }
  }

  // ============================================
  // ➕ SALVAR um único lembrete
  // ============================================
  static Future<bool> saveReminder(Reminder reminder) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final dados = reminder.toSupabase();
      dados['device_id'] = deviceId;

      await _supabase.from(_tabela).upsert(dados);
      print('✅ Lembrete salvo: ${reminder.id}');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar lembrete: $e');
      return false;
    }
  }

  // ============================================
  // 🗑️ DELETAR um lembrete
  // ============================================
  static Future<bool> deleteReminder(String id) async {
    try {
      await _supabase.from(_tabela).delete().eq('id', id);
      print('🗑️ Lembrete deletado: $id');
      return true;
    } catch (e) {
      print('❌ Erro ao deletar lembrete: $e');
      return false;
    }
  }

  // ============================================
  // 🧹 LIMPAR todos os lembretes (debug)
  // ============================================
  static Future<void> clearAll() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      await _supabase.from(_tabela).delete().eq('device_id', deviceId);
      print('🧹 Todos os lembretes foram apagados');
    } catch (e) {
      print('❌ Erro ao limpar lembretes: $e');
    }
  }
}