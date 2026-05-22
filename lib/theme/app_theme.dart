import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════
//  ENUM DE TEMAS
// ════════════════════════════════════════════════════════
enum AppTema {
  padrao,
  rosa,
  roxo,
  azul,
  verde,
  amarelo,
  laranja,
  colorido,
}

// ════════════════════════════════════════════════════════
//  DADOS DE CADA TEMA
// ════════════════════════════════════════════════════════
class AppTemaData {
  final String nome;
  final String emoji;
  final Color primary;
  final Color secondary;
  final List<Color> gradiente;
  final bool isColorido;

  const AppTemaData({
    required this.nome,
    required this.emoji,
    required this.primary,
    required this.secondary,
    required this.gradiente,
    this.isColorido = false,
  });
}

const Map<AppTema, AppTemaData> appTemas = {
  AppTema.padrao: AppTemaData(
    nome: 'padrão',
    emoji: '⚫',
    primary: Color(0xFF212121),
    secondary: Color(0xFF757575),
    gradiente: [Color(0xFF212121), Color(0xFF757575)],
  ),
  AppTema.rosa: AppTemaData(
    nome: 'rosa',
    emoji: '🩷',
    primary: Color(0xFFE91E8C),
    secondary: Color(0xFFFF6EB4),
    gradiente: [Color(0xFFE91E8C), Color(0xFFFF6EB4)],
  ),
  AppTema.roxo: AppTemaData(
    nome: 'roxo',
    emoji: '💜',
    primary: Color(0xFF7C3AED),
    secondary: Color(0xFFA78BFA),
    gradiente: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
  ),
  AppTema.azul: AppTemaData(
    nome: 'azul',
    emoji: '💙',
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF60A5FA),
    gradiente: [Color(0xFF2563EB), Color(0xFF60A5FA)],
  ),
  AppTema.verde: AppTemaData(
    nome: 'verde',
    emoji: '💚',
    primary: Color(0xFF16A34A),
    secondary: Color(0xFF4ADE80),
    gradiente: [Color(0xFF16A34A), Color(0xFF4ADE80)],
  ),
  AppTema.amarelo: AppTemaData(
    nome: 'amarelo',
    emoji: '💛',
    primary: Color(0xFFD97706),
    secondary: Color(0xFFFBBF24),
    gradiente: [Color(0xFFD97706), Color(0xFFFBBF24)],
  ),
  AppTema.laranja: AppTemaData(
    nome: 'laranja',
    emoji: '🧡',
    primary: Color(0xFFEA580C),
    secondary: Color(0xFFFB923C),
    gradiente: [Color(0xFFEA580C), Color(0xFFFB923C)],
  ),
  AppTema.colorido: AppTemaData(
    nome: 'colorido',
    emoji: '🌈',
    primary: Color(0xFFE91E8C),
    secondary: Color(0xFF7C3AED),
    gradiente: [
      Color(0xFFE91E8C),
      Color(0xFF7C3AED),
      Color(0xFF2563EB),
      Color(0xFF16A34A),
      Color(0xFFD97706),
      Color(0xFFEA580C),
    ],
    isColorido: true,
  ),
};

// helper — cor rotativa para modo colorido
const List<Color> _coresRainbow = [
  Color(0xFFE91E8C),
  Color(0xFF7C3AED),
  Color(0xFF2563EB),
  Color(0xFF16A34A),
  Color(0xFFD97706),
  Color(0xFFEA580C),
];

Color corRainbow(int index) => _coresRainbow[index % _coresRainbow.length];

// ════════════════════════════════════════════════════════
//  LIGHT / DARK THEME
// ════════════════════════════════════════════════════════
class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black87,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFE8E8E8),
        textTheme: GoogleFonts.specialEliteTextTheme(),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB0B0B0),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.specialEliteTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      );
}

// ════════════════════════════════════════════════════════
//  CORES FIXAS
// ════════════════════════════════════════════════════════
class _W {
  static const w87 = Color(0xDEFFFFFF);
  static const w70 = Color(0xB3FFFFFF);
  static const w60 = Color(0x99FFFFFF);
  static const w54 = Color(0x8AFFFFFF);
  static const w38 = Color(0x61FFFFFF);
  static const w24 = Color(0x3DFFFFFF);
  static const w12 = Color(0x1FFFFFFF);
}

// ════════════════════════════════════════════════════════
//  EXTENSÃO AppColors — via context
// ════════════════════════════════════════════════════════
extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgPage     => isDark ? const Color(0xFF121212) : const Color(0xFFE8E8E8);
  Color get bgCard     => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get bgCardDone => isDark ? const Color(0xFF181818) : Colors.grey.shade100;
  Color get bgChipSel  => isDark ? _W.w70                  : Colors.black87;

  Color get txtPrimary  => isDark ? _W.w87 : Colors.black87;
  Color get txtSecond   => isDark ? _W.w54 : Colors.black54;
  Color get txtHint     => isDark ? _W.w38 : Colors.black38;
  Color get txtDisabled => isDark ? _W.w24 : Colors.black26;

  Color get border     => isDark ? _W.w12              : Colors.grey.shade200;
  Color get borderChip => isDark ? _W.w24              : Colors.grey.shade300;

  Color get progressBg => isDark ? _W.w12 : Colors.grey.shade300;
  Color get progressFg => isDark ? _W.w70 : Colors.black54;

  Color get fabBg => isDark ? const Color(0xFF2A2A2A) : Colors.black87;
  Color get fabFg => isDark ? _W.w87                  : Colors.white;

  Color get chipSelTxt   => isDark ? Colors.black87           : Colors.white;
  Color get chipUnselTxt => isDark ? _W.w60                   : Colors.black54;
  Color get chipUnselBg  => isDark ? const Color(0xFF2A2A2A)  : Colors.white;
}