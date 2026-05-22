import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrashService {
  static const _key = 'lixeira';
  static const _diasRetencao = 30;

  Future<List<Map<String, dynamic>>> carregar() async {
    await _limparAntigos();
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString(_key);
    if (dados == null) return [];
    final lista = jsonDecode(dados) as List;
    return lista.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _salvar(List<Map<String, dynamic>> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lista));
  }

  /// Adiciona um ou vários lembretes na lixeira
  Future<void> adicionar(List<Map<String, dynamic>> lembretes) async {
    final atual = await carregar();
    final agora = DateTime.now().toIso8601String();
    for (final l in lembretes) {
      atual.add({...l, 'excluidoEm': agora});
    }
    await _salvar(atual);
  }

  /// Restaura um lembrete (remove da lixeira e retorna ele sem o campo excluidoEm)
  Future<Map<String, dynamic>?> restaurar(int index) async {
    final atual = await carregar();
    if (index < 0 || index >= atual.length) return null;
    final l = atual.removeAt(index);
    await _salvar(atual);
    l.remove('excluidoEm');
    return l;
  }

  Future<void> excluirDefinitivo(int index) async {
    final atual = await carregar();
    if (index < 0 || index >= atual.length) return;
    atual.removeAt(index);
    await _salvar(atual);
  }

  Future<void> esvaziar() async {
    await _salvar([]);
  }

  /// Remove lembretes com mais de 30 dias na lixeira
  Future<void> _limparAntigos() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString(_key);
    if (dados == null) return;
    final lista = (jsonDecode(dados) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final agora = DateTime.now();
    lista.removeWhere((l) {
      final excl = DateTime.tryParse(l['excluidoEm'] ?? '');
      if (excl == null) return true;
      return agora.difference(excl).inDays >= _diasRetencao;
    });
    await prefs.setString(_key, jsonEncode(lista));
  }

  /// Quantos dias restam até o lembrete ser apagado definitivamente
  static int diasRestantes(Map<String, dynamic> l) {
    final excl = DateTime.tryParse(l['excluidoEm'] ?? '');
    if (excl == null) return 0;
    final passados = DateTime.now().difference(excl).inDays;
    return (_diasRetencao - passados).clamp(0, _diasRetencao);
  }
}