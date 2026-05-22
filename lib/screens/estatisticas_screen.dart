import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EstatisticasScreen extends StatelessWidget {
  final List<Map<String, dynamic>> lembretes;
  const EstatisticasScreen({super.key, required this.lembretes});

  static const Map<String, Color> _cores = {
    'Medicação': Colors.red,
    'Trabalho':  Colors.blue,
    'Mercado':   Colors.green,
    'Contas':    Colors.orange,
    'Outros':    Colors.grey,
  };

  int get _total     => lembretes.length;
  int get _concl     => lembretes.where((l) => l['concluido'] == true).length;
  int get _pendentes => _total - _concl;
  double get _pct    => _total == 0 ? 0 : _concl / _total;

  Map<String, int> _contarPor(bool Function(Map) filtro) {
    final map = <String, int>{};
    for (final l in lembretes.where(filtro)) {
      final cat = l['categoria'] as String? ?? 'Outros';
      map[cat] = (map[cat] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final porCat  = _contarPor((_) => true);
    final conclCat = _contarPor((l) => l['concluido'] == true);

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('estatísticas',
            style: GoogleFonts.specialElite(
                color: Colors.white, fontSize: 20)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── RESUMO ───────────────────────────────────────
            _titulo('resumo geral'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _cardNum('$_total',     'total',      Colors.black87)),
              const SizedBox(width: 10),
              Expanded(child: _cardNum('$_concl',     'concluídos', Colors.green)),
              const SizedBox(width: 10),
              Expanded(child: _cardNum('$_pendentes', 'pendentes',  Colors.orange)),
            ]),
            const SizedBox(height: 24),

            // ── PROGRESSO GERAL ──────────────────────────────
            _titulo('progresso geral'),
            const SizedBox(height: 12),
            Container(
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
                      Text('concluídos',
                          style: GoogleFonts.specialElite(
                              fontSize: 14, color: Colors.black54)),
                      Text('${(_pct * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.specialElite(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _pct,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _total == 0
                        ? 'nenhum lembrete ainda.'
                        : '$_concl de $_total lembretes concluídos.',
                    style: GoogleFonts.specialElite(
                        fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── POR CATEGORIA ────────────────────────────────
            if (porCat.isNotEmpty) ...[
              _titulo('por categoria'),
              const SizedBox(height: 12),
              ...porCat.entries.map((e) {
                final cat   = e.key;
                final qtd   = e.value;
                final concl = conclCat[cat] ?? 0;
                final cor   = _cores[cat] ?? Colors.grey;
                final pct   = qtd == 0 ? 0.0 : concl / qtd;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                                color: cor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(cat.toLowerCase(),
                              style: GoogleFonts.specialElite(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ]),
                        Text('$concl/$qtd',
                            style: GoogleFonts.specialElite(
                                fontSize: 12, color: Colors.black45)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(cor),
                      ),
                    ),
                  ]),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _titulo(String t) => Text(t,
      style: GoogleFonts.specialElite(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87));

  Widget _cardNum(String val, String label, Color cor) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(children: [
          Text(val,
              style: GoogleFonts.specialElite(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: cor)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.specialElite(
                  fontSize: 11, color: Colors.black45)),
        ]),
      );
}