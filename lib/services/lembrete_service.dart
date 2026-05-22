import 'package:supabase_flutter/supabase_flutter.dart';

class LembreteService {
  static final _supabase = Supabase.instance.client;
  static const String _tabela = 'lembretes';

  // ════════════════════════════════════════════════════════
  //  CONVERSORES camelCase ↔ snake_case
  // ════════════════════════════════════════════════════════

  /// Converte do app (camelCase) → Supabase (snake_case)
  static Map<String, dynamic> _paraSupabase(Map<String, dynamic> l) {
    final map = <String, dynamic>{};

    if (l['titulo'] != null)         map['titulo']         = l['titulo'];
    if (l['horario'] != null)        map['horario']        = l['horario'];
    if (l['categoria'] != null)      map['categoria']      = l['categoria'];
    if (l['dias'] != null)           map['dias']           = l['dias'];
    if (l['concluido'] != null)      map['concluido']      = l['concluido'];
    if (l['dataEspecifica'] != null) map['data_especifica'] = l['dataEspecifica'];
    if (l['observacoes'] != null)    map['observacoes']    = l['observacoes'];
    if (l['prioridade'] != null)     map['prioridade']     = l['prioridade'];
    if (l['status'] != null)         map['status']         = l['status'];

    return map;
  }

  /// Converte do Supabase (snake_case) → app (camelCase)
  static Map<String, dynamic> _doSupabase(Map<String, dynamic> row) {
    return {
      'id':             row['id'],
      'titulo':         row['titulo'],
      'horario':        row['horario'],
      'categoria':      row['categoria'],
      'dias':           row['dias'] ?? [],
      'concluido':      row['concluido'] ?? false,
      'dataEspecifica': row['data_especifica'],
      'observacoes':    row['observacoes'],
      'prioridade':     row['prioridade'],
      'status':         row['status'] ?? 'ativo',
      'concluidoEm':    row['concluido_em'],
      'excluidoEm':     row['excluido_em'],
      'criadoEm':       row['criado_em'],
    };
  }

  // ════════════════════════════════════════════════════════
  //  CARREGAR (só ativos)
  // ════════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> carregarLembretes() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('⚠️ Usuário não logado');
        return [];
      }

      final response = await _supabase
          .from(_tabela)
          .select()
          .eq('user_id', user.id)
          .eq('status', 'ativo')
          .order('horario', ascending: true);

      final lista = (response as List)
          .map((row) => _doSupabase(Map<String, dynamic>.from(row)))
          .toList();

      print('☁️ Carregados ${lista.length} lembretes ativos');
      return lista;
    } catch (e) {
      print('❌ Erro ao carregar: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════
  //  CARREGAR HISTÓRICO (concluídos + excluídos)
  // ════════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> carregarHistorico() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from(_tabela)
          .select()
          .eq('user_id', user.id)
          .inFilter('status', ['concluido', 'excluido'])
          .order('concluido_em', ascending: false);

      final lista = (response as List)
          .map((row) => _doSupabase(Map<String, dynamic>.from(row)))
          .toList();

      print('📜 Carregados ${lista.length} itens do histórico');
      return lista;
    } catch (e) {
      print('❌ Erro ao carregar histórico: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════
  //  ADICIONAR LEMBRETE
  // ════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>?> adicionarLembrete(
      Map<String, dynamic> lembrete) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('⚠️ Usuário não logado');
        return null;
      }

      final dados = _paraSupabase(lembrete);
      dados['user_id'] = user.id;
      dados['status']  = 'ativo';

      final response = await _supabase
          .from(_tabela)
          .insert(dados)
          .select()
          .single();

      final criado = _doSupabase(Map<String, dynamic>.from(response));
      print('✅ Lembrete criado: ${criado['titulo']}');
      return criado;
    } catch (e) {
      print('❌ Erro ao adicionar: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  //  ATUALIZAR LEMBRETE (editar)
  // ════════════════════════════════════════════════════════
  static Future<bool> atualizarLembrete(
      String id, Map<String, dynamic> dados) async {
    try {
      final dadosSnake = _paraSupabase(dados);
      await _supabase
          .from(_tabela)
          .update(dadosSnake)
          .eq('id', id);
      print('✅ Lembrete atualizado: $id');
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  //  MARCAR COMO CONCLUÍDO (vai pro histórico)
  // ════════════════════════════════════════════════════════
  static Future<bool> marcarComoConcluido(String id) async {
    try {
      await _supabase.from(_tabela).update({
        'concluido': true,
        'concluido_em': DateTime.now().toIso8601String(),
        // ❌ NÃO mexe no status — fica 'ativo'
      }).eq('id', id);
      print('✅ Marcado como concluído: $id');
      return true;
    } catch (e) {
      print('❌ Erro ao concluir: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  //  MARCAR COMO EXCLUÍDO (vai pro histórico)
  // ════════════════════════════════════════════════════════
  static Future<bool> marcarComoExcluido(String id) async {
    try {
      await _supabase.from(_tabela).update({
        'status': 'excluido',
        'excluido_em': DateTime.now().toIso8601String(),
      }).eq('id', id);
      print('🗑️ Movido pro histórico: $id');
      return true;
    } catch (e) {
      print('❌ Erro ao excluir: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  //  RESTAURAR DO HISTÓRICO (volta a ser ativo)
  // ════════════════════════════════════════════════════════
  static Future<bool> restaurarLembrete(String id) async {
    try {
      await _supabase.from(_tabela).update({
        'concluido': false,
        'concluido_em': null,
        // ❌ não mexe no status
      }).eq('id', id);
      print('♻️ Desmarcado: $id');
      return true;
    } catch (e) {
      print('❌ Erro ao desmarcar: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  //  DELETAR PERMANENTEMENTE (do histórico)
  // ════════════════════════════════════════════════════════
  static Future<bool> deletarPermanente(String id) async {
    try {
      await _supabase.from(_tabela).delete().eq('id', id);
      print('💥 Deletado permanentemente: $id');
      return true;
    } catch (e) {
      print('❌ Erro ao deletar: $e');
      return false;
    }
  }
}