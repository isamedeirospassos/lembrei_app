import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  static const _key = 'categorias_customizadas';

  // categorias padrão (semente inicial)
  static final List<Map<String, dynamic>> _padrao = [
    {'nome': 'Medicação', 'icone': Icons.medical_services.codePoint, 'cor': Colors.red.value},
    {'nome': 'Trabalho',  'icone': Icons.work.codePoint,             'cor': Colors.blue.value},
    {'nome': 'Mercado',   'icone': Icons.shopping_cart.codePoint,    'cor': Colors.green.value},
    {'nome': 'Contas',    'icone': Icons.attach_money.codePoint,     'cor': Colors.orange.value},
    {'nome': 'Outros',    'icone': Icons.label.codePoint,            'cor': Colors.grey.value},
  ];

  // ícones disponíveis pro usuário escolher
  static const List<IconData> iconesDisponiveis = [
    Icons.medical_services, Icons.work, Icons.shopping_cart, Icons.attach_money,
    Icons.label, Icons.fitness_center, Icons.school, Icons.home, Icons.favorite,
    Icons.pets, Icons.restaurant, Icons.local_cafe, Icons.cake, Icons.book,
    Icons.music_note, Icons.movie, Icons.sports_esports, Icons.flight,
    Icons.directions_car, Icons.beach_access, Icons.celebration, Icons.star,
    Icons.lightbulb, Icons.water_drop, Icons.eco, Icons.psychology,
  ];

  // cores disponíveis
  static final List<Color> coresDisponiveis = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey,
  ];

  Future<List<Map<String, dynamic>>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString(_key);
    if (dados == null) {
      await salvar(_padrao);
      return List<Map<String, dynamic>>.from(_padrao);
    }
    final lista = jsonDecode(dados) as List;
    return lista.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> salvar(List<Map<String, dynamic>> cats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(cats));
  }

  Future<void> adicionar(String nome, IconData icone, Color cor) async {
    final cats = await carregar();
    cats.add({'nome': nome, 'icone': icone.codePoint, 'cor': cor.value});
    await salvar(cats);
  }

  Future<void> editar(int index, String nome, IconData icone, Color cor) async {
    final cats = await carregar();
    if (index >= 0 && index < cats.length) {
      cats[index] = {'nome': nome, 'icone': icone.codePoint, 'cor': cor.value};
      await salvar(cats);
    }
  }

  Future<void> excluir(int index) async {
    final cats = await carregar();
    if (index >= 0 && index < cats.length) {
      cats.removeAt(index);
      await salvar(cats);
    }
  }

  // helpers de conversão
  static IconData iconeFromInt(int code) {
    // ignore: non_const_argument_for_const_parameter
    return IconData(code, fontFamily: 'MaterialIcons');
  }

  static Color corFromInt(int value) => Color(value);
}