import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EstatisticasScreen extends StatelessWidget {
  final List<Map<String, dynamic>> lembretes;

  const EstatisticasScreen({super.key, required this.lembretes});

  final Map<String, Color> _coresCategorias = const {
    'Medicação': Colors.red,
    'Trabalho': Colors.blue,
    'Mercado': Colors.green,
    'Contas': Colors.orange,
    'Outros': Colors.grey,
  };

  int get _total => lembretes.length;
  int get _concluidos => lembretes.where((l) => l['concluido'] == true).length;
  int get _pendentes => _total - _concluidos;
  double get _percentual => _total == 0 ? 0 : (_concluidos / _total * 100);

  Map<String, int> get _porCategoria {
    final Map<String, int> mapa = {};
    for (final l in lembretes) {
      final cat = l['categoria'] as String? ?? 'Outros';
      mapa[cat] = (mapa[cat] ?? 0) + 1;
    }
    return mapa;
  }

  Map<String, int> get _concluidosPorCategoria {
    final Map<String, int> mapa = {};
    for (final l in lembretes.where((l) => l['concluido'] == true)) {
      final cat = l['categoria'] as String? ?? 'Outros';
      mapa[cat] = (mapa[cat] ?? 0) + 1;
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          'estatísticas',
          style: GoogleFonts.specialElite(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumoGeral(),
            const SizedBox(height: 24),
            _buildProgressoGeral(),
            const SizedBox(height: 24),
            _buildPorCategoria(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoGeral() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'resumo geral',
          style: GoogleFonts.specialElite(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _cardStat('$_total', 'total', Colors.black87)),
            const SizedBox(width: 12),
            Expanded(child: _cardStat('$_concluidos', 'concluídos', Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _cardStat('$_pendentes', 'pendentes', Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _cardStat(String valor, String label, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: GoogleFonts.specialElite(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.specialElite(
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressoGeral() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'progresso geral',
                style: GoogleFonts.specialElite(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_percentual.toStringAsFixed(0)}%',
                style: GoogleFonts.specialElite(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _percentual / 100,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black54),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _total == 0
                ? 'nenhum lembrete cadastrado.'
                : '$_concluidos de $_total lembretes concluídos.',
            style: GoogleFonts.specialElite(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPorCategoria() {
    final porCat = _porCategoria;
    if (porCat.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'por categoria',
          style: GoogleFonts.specialElite(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...porCat.entries.map((entry) {
          final cat = entry.key;
          final qtd = entry.value;
          final concl = _concluidosPorCategoria[cat] ?? 0;
          final cor = _coresCategorias[cat] ?? Colors.grey;
          final pct = qtd == 0 ? 0.0 : concl / qtd;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: cor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat.toLowerCase(),
                          style: GoogleFonts.specialElite(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$concl/$qtd concluídos',
                      style: GoogleFonts.specialElite(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(cor),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}