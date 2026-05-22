import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class EditReminderScreen extends StatefulWidget {
  final Map<String, dynamic> lembrete;
  final int index;

  const EditReminderScreen({
    super.key,
    required this.lembrete,
    required this.index,
  });

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  // ── controllers ───────────────────────────────────────────
  final TextEditingController _tituloController    = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  // ── horario ───────────────────────────────────────────────
  TimeOfDay _horarioSelecionado = TimeOfDay.now();

  // ── categoria ─────────────────────────────────────────────
  String _categoriaSelecionada = 'Medicacao';

  // ── prioridade ────────────────────────────────────────────
  String _prioridade = 'Media';

  // ── modo repeticao: 'dias' | 'data' ───────────────────────
  String _modoRepeticao = 'dias';

  // ── data especifica ───────────────────────────────────────
  DateTime? _dataSelecionada;

  // ── dias da semana ────────────────────────────────────────
  final Map<String, bool> _diasSemana = {
    'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false,
    'Sex': false, 'Sab': false, 'Dom': false,
  };

  // ── listas fixas ──────────────────────────────────────────
  final List<Map<String, dynamic>> _categorias = [
    {'nome': 'Medicacao', 'icone': Icons.medical_services, 'cor': Colors.red},
    {'nome': 'Trabalho',  'icone': Icons.work,             'cor': Colors.blue},
    {'nome': 'Mercado',   'icone': Icons.shopping_cart,    'cor': Colors.green},
    {'nome': 'Contas',    'icone': Icons.attach_money,     'cor': Colors.orange},
    {'nome': 'Outros',    'icone': Icons.label,            'cor': Colors.grey},
  ];

  final List<Map<String, dynamic>> _prioridades = [
    {'label': 'Baixa', 'cor': Colors.green,  'icone': Icons.arrow_downward},
    {'label': 'Media', 'cor': Colors.orange, 'icone': Icons.remove},
    {'label': 'Alta',  'cor': Colors.red,    'icone': Icons.arrow_upward},
  ];

  // ── init ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final l = widget.lembrete;

    _tituloController.text    = l['titulo']     ?? '';
    _descricaoController.text = l['descricao']  ?? '';
    _categoriaSelecionada     = l['categoria']  ?? 'Medicacao';
    _prioridade               = l['prioridade'] ?? 'Media';

    final partes = (l['horario'] ?? '00:00').split(':');
    _horarioSelecionado = TimeOfDay(
      hour:   int.tryParse(partes[0]) ?? 0,
      minute: int.tryParse(partes[1]) ?? 0,
    );

    if (l['dataEspecifica'] != null) {
      _modoRepeticao   = 'data';
      _dataSelecionada = DateTime.tryParse(l['dataEspecifica']);
    } else {
      _modoRepeticao = 'dias';
      for (final d in List<String>.from(l['dias'] ?? [])) {
        if (_diasSemana.containsKey(d)) _diasSemana[d] = true;
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // ── selecionar horario ────────────────────────────────────
  Future<void> _selecionarHorario() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _horarioSelecionado,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black87),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _horarioSelecionado = t);
  }

  // ── selecionar data ───────────────────────────────────────
  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? hoje,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 5),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black87),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dataSelecionada = d);
  }

  // ── todos os dias ─────────────────────────────────────────
  void _selecionarTodosDias() {
    setState(() {
      final todos = _diasSemana.values.every((v) => v);
      _diasSemana.updateAll((k, v) => !todos);
    });
  }

  // ── salvar edicao ─────────────────────────────────────────
  Future<void> _salvarEdicao() async {
    if (_tituloController.text.trim().isEmpty) {
      _snack('digite um titulo!');
      return;
    }
    if (_modoRepeticao == 'data' && _dataSelecionada == null) {
      _snack('selecione uma data especifica!');
      return;
    }

    final prefs     = await SharedPreferences.getInstance();
    final dados     = prefs.getString('lembretes');
    final lista     = dados != null ? jsonDecode(dados) as List : [];
    final lembretes = lista.map((e) => Map<String, dynamic>.from(e)).toList();

    final horarioFormatado =
        '${_horarioSelecionado.hour.toString().padLeft(2, '0')}:'
        '${_horarioSelecionado.minute.toString().padLeft(2, '0')}';

    final diasSelecionados = _modoRepeticao == 'dias'
        ? _diasSemana.entries.where((e) => e.value).map((e) => e.key).toList()
        : <String>[];

    // ── cancela notificacao antiga ────────────────────────
    final idAntigo = widget.lembrete['id'] as int;
    await NotificationService().cancelarNotificacao(idAntigo);

    // ── atualiza na lista ─────────────────────────────────
    if (widget.index < lembretes.length) {
      lembretes[widget.index] = {
        ...lembretes[widget.index],
        'titulo':         _tituloController.text.trim(),
        'descricao':      _descricaoController.text.trim(),
        'horario':        horarioFormatado,
        'dias':           diasSelecionados,
        'categoria':      _categoriaSelecionada,
        'prioridade':     _prioridade,
        'dataEspecifica': _modoRepeticao == 'data'
            ? _dataSelecionada!.toIso8601String()
            : null,
        'concluido': widget.lembrete['concluido'] ?? false,
      };
    }

    await prefs.setString('lembretes', jsonEncode(lembretes));

    // ── agenda nova notificacao ───────────────────────────
    await NotificationService().agendarNotificacao(
      id:             idAntigo,
      titulo:         _tituloController.text.trim(),
      corpo:          _descricaoController.text.trim().isNotEmpty
                          ? _descricaoController.text.trim()
                          : 'lembrete: ${_tituloController.text.trim()}',
      hora:           _horarioSelecionado.hour,
      minuto:         _horarioSelecionado.minute,
      dias:           diasSelecionados,
      dataEspecifica: _modoRepeticao == 'data' ? _dataSelecionada : null,
      prioridade:     _prioridade,
    );

    if (mounted) Navigator.pop(context, true);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.specialElite()),
      backgroundColor: Colors.red[700],
    ));
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final todos = _diasSemana.values.every((v) => v);
    final algum = _diasSemana.values.any((v) => v);

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'editar lembrete',
          style: GoogleFonts.specialElite(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── TITULO ───────────────────────────────────────
            _label('titulo'),
            const SizedBox(height: 8),
            TextField(
              controller: _tituloController,
              style: GoogleFonts.specialElite(),
              decoration: _inputDec('ex: tomar remedio', Icons.edit),
            ),
            const SizedBox(height: 20),

            // ── DESCRICAO ────────────────────────────────────
            _label('descricao (opcional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _descricaoController,
              style: GoogleFonts.specialElite(fontSize: 13),
              maxLines: 3,
              decoration: _inputDec(
                'ex: tomar com agua, apos a refeicao...',
                Icons.notes,
              ),
            ),
            const SizedBox(height: 20),

            // ── PRIORIDADE ───────────────────────────────────
            _label('prioridade'),
            const SizedBox(height: 8),
            _cardContainer(
              child: Row(
                children: _prioridades.map((p) {
                  final sel = _prioridade == p['label'];
                  final cor = p['cor'] as Color;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _prioridade = p['label'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? cor : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sel ? cor : Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(p['icone'] as IconData,
                                size: 18,
                                color: sel ? Colors.white : Colors.grey[600]),
                            const SizedBox(height: 4),
                            Text(
                              (p['label'] as String).toLowerCase(),
                              style: GoogleFonts.specialElite(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── CATEGORIA ────────────────────────────────────
            _label('categoria'),
            const SizedBox(height: 8),
            _cardContainer(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categorias.map((cat) {
                  final sel = _categoriaSelecionada == cat['nome'];
                  final cor = cat['cor'] as Color;
                  return GestureDetector(
                    onTap: () => setState(
                        () => _categoriaSelecionada = cat['nome'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? cor : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sel ? cor : Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat['icone'] as IconData,
                              size: 18,
                              color: sel ? Colors.white : Colors.grey[700]),
                          const SizedBox(width: 6),
                          Text(
                            cat['nome'] as String,
                            style: GoogleFonts.specialElite(
                              color: sel ? Colors.white : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── HORARIO ──────────────────────────────────────
            _label('horario'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selecionarHorario,
              child: _cardContainer(
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.black54),
                    const SizedBox(width: 12),
                    Text(
                      '${_horarioSelecionado.hour.toString().padLeft(2, '0')}:'
                      '${_horarioSelecionado.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.specialElite(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.black54, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── MODO REPETICAO ────────────────────────────────
            _label('quando repetir?'),
            const SizedBox(height: 8),
            _cardContainer(
              child: Row(
                children: [
                  _modoBtn('dias', Icons.repeat,         'dias da semana'),
                  const SizedBox(width: 8),
                  _modoBtn('data', Icons.calendar_today, 'data especifica'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── DIAS DA SEMANA ────────────────────────────────
            if (_modoRepeticao == 'dias') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label('dias da semana'),
                  TextButton.icon(
                    onPressed: _selecionarTodosDias,
                    icon: Icon(
                      todos ? Icons.clear_all : Icons.select_all,
                      color: Colors.black87, size: 18,
                    ),
                    label: Text(
                      todos ? 'limpar' : 'todos',
                      style: GoogleFonts.specialElite(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              _avisoRepeticao(algum),
              _cardContainer(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _diasSemana.keys.map((dia) {
                    final sel = _diasSemana[dia]!;
                    return GestureDetector(
                      onTap: () => setState(() => _diasSemana[dia] = !sel),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? Colors.black87 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sel
                                  ? Colors.black87
                                  : Colors.grey[300]!),
                        ),
                        child: Text(
                          dia,
                          style: GoogleFonts.specialElite(
                            color: sel ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // ── DATA ESPECIFICA ───────────────────────────────
            if (_modoRepeticao == 'data') ...[
              _label('data'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selecionarData,
                child: _cardContainer(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.black54),
                      const SizedBox(width: 12),
                      Text(
                        _dataSelecionada == null
                            ? 'toque para escolher a data'
                            : '${_dataSelecionada!.day.toString().padLeft(2, '0')}/'
                              '${_dataSelecionada!.month.toString().padLeft(2, '0')}/'
                              '${_dataSelecionada!.year}',
                        style: GoogleFonts.specialElite(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _dataSelecionada == null
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.black54, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.purple[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'lembrete unico - dispara somente nessa data',
                        style: GoogleFonts.specialElite(
                            fontSize: 12, color: Colors.purple[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── BOTAO SALVAR ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvarEdicao,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  'salvar edicao',
                  style: GoogleFonts.specialElite(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS DE UI ─────────────────────────────────────────
  Widget _label(String t) => Text(
        t,
        style: GoogleFonts.specialElite(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      );

  Widget _cardContainer({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: child,
      );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.specialElite(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.black54),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black87)),
      );

  Widget _modoBtn(String modo, IconData icon, String texto) {
    final sel = _modoRepeticao == modo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _modoRepeticao = modo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? Colors.black87 : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: sel ? Colors.black87 : Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16,
                  color: sel ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                texto,
                style: GoogleFonts.specialElite(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: sel ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avisoRepeticao(bool algum) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: algum ? Colors.blue[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: algum ? Colors.blue[200]! : Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(algum ? Icons.repeat : Icons.today,
                size: 16,
                color: algum ? Colors.blue[700] : Colors.orange[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                algum
                    ? 'lembrete recorrente nos dias selecionados'
                    : 'sem dias - toca apenas hoje',
                style: GoogleFonts.specialElite(
                  fontSize: 12,
                  color: algum ? Colors.blue[700] : Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
      );
}