import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ThemePickerScreen extends StatelessWidget {
  final AppTema temaSelecionado;
  final bool darkMode;
  final Function(AppTema) onTemaChanged;

  const ThemePickerScreen({
    super.key,
    required this.temaSelecionado,
    required this.darkMode,
    required this.onTemaChanged,
  });

  Color get _bg     => darkMode ? const Color(0xFF121212) : const Color(0xFFE8E8E8);
  Color get _bgCard => darkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _txt    => darkMode ? const Color(0xDEFFFFFF) : Colors.black87;
  Color get _txtSub => darkMode ? const Color(0x8AFFFFFF) : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _txt, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'escolha um tema',
          style: GoogleFonts.specialElite(
            color: _txt,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'cor de destaque do app',
              style: GoogleFonts.specialElite(
                color: _txtSub,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: appTemas.length,
                itemBuilder: (_, i) {
                  final tema = AppTema.values[i];
                  final data = appTemas[tema]!;
                  final selecionado = tema == temaSelecionado;

                  return GestureDetector(
                    onTap: () {
                      onTemaChanged(tema);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selecionado
                              ? data.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selecionado
                            ? [
                                BoxShadow(
                                  color: data.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // preview do gradiente
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: data.gradiente,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: selecionado
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 22)
                                : Center(
                                    child: Text(
                                      data.emoji,
                                      style:
                                          const TextStyle(fontSize: 20),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.nome,
                            style: GoogleFonts.specialElite(
                              color: selecionado
                                  ? data.primary
                                  : _txt,
                              fontSize: 13,
                              fontWeight: selecionado
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (selecionado)
                            Text(
                              'ativo',
                              style: GoogleFonts.specialElite(
                                color: data.primary,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}