import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> lembrete;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onConcluir;

  const DetailScreen({
    super.key,
    required this.lembrete,
    required this.onEditar,
    required this.onExcluir,
    required this.onConcluir,
  });

  Color _corCategoria(String categoria) {
    switch (categoria) {
      case 'Medicação':
        return Colors.red[400]!;
      case 'Trabalho':
        return Colors.blue[400]!;
      case 'Mercado':
        return Colors.green[400]!;
      case 'Contas':
        return Colors.orange[400]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _iconeCategoria(String categoria) {
    switch (categoria) {
      case 'Medicação':
        return Icons.medical_services;
      case 'Trabalho':
        return Icons.work;
      case 'Mercado':
        return Icons.shopping_cart;
      case 'Contas':
        return Icons.attach_money;
      default:
        return Icons.label;
    }
  }

  String _formatarDias(List<dynamic> dias) {
    if (dias.isEmpty) return '📅 apenas hoje';
    if (dias.length == 7) return '🔁 todos os dias';
    return '🔁 ${dias.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final categoria = lembrete['categoria'] ?? 'Outros';
    final cor = _corCategoria(categoria);
    final concluido = lembrete['concluido'] ?? false;
    final dias = lembrete['dias'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.15),
                border: Border(
                  bottom: BorderSide(color: cor.withOpacity(0.3), width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Icon(Icons.arrow_back,
                              size: 20, color: Colors.black87),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: concluido
                              ? Colors.green[400]
                              : Colors.orange[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          concluido ? '✓ concluído' : '⏳ pendente',
                          style: GoogleFonts.specialElite(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: cor, width: 2),
                    ),
                    child: Icon(
                      _iconeCategoria(categoria),
                      color: cor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lembrete['titulo'] ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.specialElite(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      decoration:
                          concluido ? TextDecoration.lineThrough : null,
                      decorationThickness: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categoria,
                    style: GoogleFonts.specialElite(
                      fontSize: 16,
                      color: cor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoCard(
                      icone: Icons.access_time,
                      titulo: 'horário',
                      valor: lembrete['horario'] ?? '--:--',
                      cor: cor,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icone: Icons.calendar_today,
                      titulo: 'dias',
                      valor: _formatarDias(dias),
                      cor: cor,
                    ),
                    const SizedBox(height: 12),
                    if (dias.isNotEmpty && dias.length < 7) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'dias da semana',
                              style: GoogleFonts.specialElite(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                'Seg', 'Ter', 'Qua', 'Qui',
                                'Sex', 'Sáb', 'Dom'
                              ].map((dia) {
                                final ativo = dias.contains(dia);
                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: ativo
                                        ? cor.withOpacity(0.2)
                                        : Colors.grey[100],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ativo ? cor : Colors.grey[300]!,
                                      width: ativo ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      dia.substring(0, 1),
                                      style: GoogleFonts.specialElite(
                                        fontSize: 13,
                                        color: ativo ? cor : Colors.grey[400],
                                        fontWeight: ativo
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          onConcluir();
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          concluido ? Icons.refresh : Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: Text(
                          concluido
                              ? 'marcar como pendente'
                              : 'marcar como concluído',
                          style: GoogleFonts.specialElite(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: concluido
                              ? Colors.orange[600]
                              : Colors.green[500],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onEditar();
                        },
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.black87),
                        label: Text(
                          'editar lembrete',
                          style: GoogleFonts.specialElite(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: Colors.black87, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmarExclusao(context),
                        icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                        label: Text(
                          'excluir lembrete',
                          style: GoogleFonts.specialElite(
                            fontSize: 16,
                            color: Colors.red[400],
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.red[400]!, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icone,
    required String titulo,
    required String valor,
    required Color cor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: cor, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: GoogleFonts.specialElite(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                valor,
                style: GoogleFonts.specialElite(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFE8E8E8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'excluir lembrete?',
          style: GoogleFonts.specialElite(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'essa ação não pode ser desfeita.',
          style: GoogleFonts.specialElite(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'cancelar',
              style: GoogleFonts.specialElite(color: Colors.black87),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              onExcluir();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'excluir',
              style: GoogleFonts.specialElite(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}