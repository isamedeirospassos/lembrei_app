import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/category_service.dart';
import '../services/lembrete_service.dart';
import '../theme/app_theme.dart';
import 'add_reminder_screen.dart';
import 'edit_reminder_screen.dart';
import 'estatisticas_screen.dart';
import 'categorias_screen.dart';
import 'package:home_widget/home_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _lembretes = [];
  String _categoriaSelecionada = 'Todos';
  String _statusSelecionado = 'Todos';
  bool _darkMode = false;
  AppTema _temaAtual = AppTema.padrao;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── CATEGORIAS DINÂMICAS ──────────────────────────────
  final _categoryService = CategoryService();
  List<Map<String, dynamic>> _categoriasCustom = [];

  List<String> get _categorias =>
      ['Todos', ..._categoriasCustom.map((c) => c['nome'] as String)];

  Future<void> _carregarCategorias() async {
    final cats = await _categoryService.carregar();
    if (mounted) setState(() => _categoriasCustom = cats);
  }

  Color _corCategoria(String nome) {
    final c = _categoriasCustom.firstWhere(
      (e) => e['nome'] == nome,
      orElse: () => {'cor': Colors.grey.value},
    );
    return CategoryService.corFromInt(c['cor']);
  }

  IconData _iconeCategoria(String nome) {
    final c = _categoriasCustom.firstWhere(
      (e) => e['nome'] == nome,
      orElse: () => {'icone': Icons.label.codePoint},
    );
    return CategoryService.iconeFromInt(c['icone']);
  }

  final List<Map<String, dynamic>> _statusOpcoes = [
    {'label': 'Todos',      'icon': Icons.list_alt_outlined},
    {'label': 'Pendentes',  'icon': Icons.radio_button_unchecked},
    {'label': 'Concluídos', 'icon': Icons.check_circle_outline},
  ];

  // ── getters dark/light ─────────────────────────────────
  Color get _bgPage      => _darkMode ? const Color(0xFF121212) : const Color(0xFFE8E8E8);
  Color get _bgCard      => _darkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _bgCardDone  => _darkMode ? const Color(0xFF181818) : Colors.grey.shade100;
  Color get _txtPrimary  => _darkMode ? const Color(0xDEFFFFFF) : Colors.black87;
  Color get _txtSecond   => _darkMode ? const Color(0x8AFFFFFF) : Colors.black54;
  Color get _txtHint     => _darkMode ? const Color(0x61FFFFFF) : Colors.black38;
  Color get _txtDisabled => _darkMode ? const Color(0x3DFFFFFF) : Colors.black26;
  Color get _border      => _darkMode ? const Color(0x1FFFFFFF) : Colors.grey.shade200;
  Color get _chipUnselBg => _darkMode ? const Color(0xFF2A2A2A) : Colors.white;
  Color get _chipBorder  => _darkMode ? const Color(0x3DFFFFFF) : const Color(0xFFFFFFFF);
  Color get _progressBg  => _darkMode ? const Color(0x1FFFFFFF) : Colors.grey.shade300;

  // ── getters de tema ────────────────────────────────────
  AppTemaData get _tema        => appTemas[_temaAtual]!;
  Color       get _corPrimaria => _tema.primary;
  bool        get _isColorido  => _tema.isColorido;

  Color get _fabBg {
    if (_temaAtual == AppTema.padrao) {
      return _darkMode ? const Color(0xFF2A2A2A) : Colors.black87;
    }
    return _corPrimaria;
  }
  Color get _fabFg => Colors.white;

  Color get _progressFg => _temaAtual == AppTema.padrao
      ? (_darkMode ? const Color(0xB3FFFFFF) : Colors.black54)
      : _corPrimaria;

  Color _chipCatSelColor(int index) {
    if (_isColorido) return corRainbow(index);
    if (_temaAtual == AppTema.padrao) {
      return _darkMode ? const Color(0xFF444444) : Colors.black87;
    }
    return _corPrimaria;
  }

  // ════════════════════════════════════════════════════════
  //  INIT / DISPOSE
  // ════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _carregarPrefs();
    _carregarCategorias();
    _carregar().then((_) => _atualizarWidget());
    onConcluidoGlobal = (id) {
      if (mounted) _carregar().then((_) => _atualizarWidget());
    };
  }

  @override
  void dispose() {
    onConcluidoGlobal = null;
    _searchController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════
  //  PREFS
  // ════════════════════════════════════════════════════════
  Future<void> _carregarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode  = prefs.getBool('darkMode') ?? false;
      final idx  = prefs.getInt('appTema') ?? 0;
      _temaAtual = AppTema.values[idx];
    });
  }

  Future<void> _toggleTema() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkMode = !_darkMode);
    await prefs.setBool('darkMode', _darkMode);
  }

  Future<void> _salvarTema(AppTema tema) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _temaAtual = tema);
    await prefs.setInt('appTema', tema.index);
  }

  // ════════════════════════════════════════════════════════
  //  DADOS
  // ════════════════════════════════════════════════════════
  Future<void> _carregar() async {
    // 1️⃣ Tenta carregar da NUVEM primeiro (Supabase)
    final dadosNuvem = await LembreteService.carregarLembretes();

    if (dadosNuvem.isNotEmpty) {
      if (mounted) {
        setState(() {
          _lembretes = dadosNuvem;
          _ordenar();
        });
      }
      // Salva localmente também (cache offline)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lembretes', jsonEncode(_lembretes));
      print('☁️ Carregado da nuvem: ${_lembretes.length} lembretes');
      return;
    }

    // 2️⃣ Se nuvem vazia ou sem internet, usa cache local
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString('lembretes');
    if (dados != null) {
      final lista = jsonDecode(dados) as List<dynamic>;
      if (mounted) {
        setState(() {
          _lembretes = lista.map((e) => Map<String, dynamic>.from(e)).toList();
          _ordenar();
        });
      }
      print('📱 Carregado do cache local: ${_lembretes.length} lembretes');
    }
  }

  void _ordenar() {
    _lembretes.sort((a, b) {
      final conclA = a['concluido'] == true ? 1 : 0;
      final conclB = b['concluido'] == true ? 1 : 0;
      if (conclA != conclB) return conclA.compareTo(conclB);
      final pA = _toMin(a['horario'] ?? '00:00');
      final pB = _toMin(b['horario'] ?? '00:00');
      return pA.compareTo(pB);
    });
  }

  int _toMin(String horario) {
    final p = horario.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  bool _estaAtrasado(Map<String, dynamic> l) {
    if (l['concluido'] == true) return false;

    final horario = l['horario'] as String? ?? '00:00';
    final partes = horario.split(':');
    final h = int.tryParse(partes[0]) ?? 0;
    final m = int.tryParse(partes[1]) ?? 0;
    final agora = DateTime.now();

    // ─── 1️⃣ DATA ESPECÍFICA ───
    final dataEsp = l['dataEspecifica'] as String?;
    if (dataEsp != null && dataEsp.isNotEmpty) {
      try {
        final dataLembrete = DateTime.parse(dataEsp);
        final horaLembrete = DateTime(
          dataLembrete.year,
          dataLembrete.month,
          dataLembrete.day,
          h,
          m,
        );
        final atrasado = agora.isAfter(horaLembrete);
        print('🔍 ${l['titulo']} | data específica: $dataEsp | ${atrasado ? "⚠️ ATRASADO" : "✅ no prazo"}');
        return atrasado;
      } catch (e) {
        print('❌ Erro ao parsear data específica: $e');
        return false;
      }
    }

    // ─── 2️⃣ DIAS DA SEMANA ───
    final dias = List<String>.from(l['dias'] ?? []);
    final diaSemana = ['seg','ter','qua','qui','sex','sáb','dom'][agora.weekday - 1];

    print('🔍 ${l['titulo']} | dias: $dias | hoje: $diaSemana | horario: $horario');

    // se não tem dias E não tem data → considera "todo dia"
    final ehHoje = dias.isEmpty || dias.any((d) => d.toLowerCase().startsWith(diaSemana));
    if (!ehHoje) {
      print('   ❌ não é hoje');
      return false;
    }

    final horaLembrete = DateTime(agora.year, agora.month, agora.day, h, m);
    final atrasado = agora.isAfter(horaLembrete);
    print('   ${atrasado ? "⚠️ ATRASADO" : "✅ no prazo"}');
    return atrasado;
  }

  Future<void> _salvarCacheLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lembretes', jsonEncode(_lembretes));
  }

  Future<void> _atualizarWidget() async {
    final hoje = DateTime.now();
    final diaSemana = ['seg','ter','qua','qui','sex','sáb','dom'][hoje.weekday - 1];

    final lembretes = _lembretes.where((l) {
      final dias = List<String>.from(l['dias'] ?? []);
      if (dias.isEmpty) return true;
      return dias.any((d) => d.toLowerCase().startsWith(diaSemana));
    }).toList();

    String texto;
    if (lembretes.isEmpty) {
      texto = 'nenhum lembrete hoje ✨';
    } else {
      texto = lembretes.map((l) {
        final horario = l['horario'] as String? ?? '';
        final check   = l['concluido'] == true ? '✓' : '•';
        return '$check $horario  ${l['titulo']}';
      }).join('\n');
    }

    final pendentes = lembretes.where((l) => l['concluido'] != true).length;

    await HomeWidget.saveWidgetData<String>('widget_title', '📋 hoje');
    await HomeWidget.saveWidgetData<String>('widget_lembretes', texto);
    await HomeWidget.saveWidgetData<String>(
      'widget_footer',
      pendentes > 0
          ? '$pendentes pendente${pendentes > 1 ? 's' : ''}'
          : lembretes.isEmpty ? '' : 'tudo feito! 🎉',
    );

    await HomeWidget.updateWidget(androidName: 'LembreiWidgetProvider');
  }

  Future<void> _toggleConcluido(int index) async {
    final lembrete = _lembretes[index];
    final id = lembrete['id']?.toString();
    final estaConcluido = lembrete['concluido'] == true;

    if (id == null) return;

    if (!estaConcluido) {
      await LembreteService.marcarComoConcluido(id);
      final notifId = lembrete['id'] is int ? lembrete['id'] as int : 0;
      await NotificationService().cancelarNotificacao(notifId);
      setState(() {
        _lembretes[index]['concluido'] = true;  // ← só marca, NÃO remove
        _ordenar();
      });
    } else {
      await LembreteService.restaurarLembrete(id);
      setState(() {
        _lembretes[index]['concluido'] = false;
        _ordenar();
      });
    }

    await _salvarCacheLocal();
    await _atualizarWidget();
  }

  Future<void> _deletar(int index) async {
    final lembrete = _lembretes[index];
    final id = lembrete['id']?.toString();
    final notifId = lembrete['id'] is int ? lembrete['id'] as int : 0;

    if (id == null) return;

    await NotificationService().cancelarNotificacao(notifId);
    await LembreteService.marcarComoExcluido(id);

    setState(() => _lembretes.removeAt(index));
    await _salvarCacheLocal();
    await _atualizarWidget();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('lembrete movido pro histórico 🗑️',
              style: GoogleFonts.specialElite()),
          backgroundColor: Colors.grey[800],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _limparConcluidos() async {
    final concluidos = _lembretes.where((l) => l['concluido'] == true).toList();
    for (final l in concluidos) {
      final notifId = l['id'] is int ? l['id'] as int : 0;
      final idStr = l['id']?.toString();
      await NotificationService().cancelarNotificacao(notifId);
      if (idStr != null) {
        // 👇 Agora SIM vai pro histórico (muda status)
        await LembreteService.marcarComoExcluido(idStr);
      }
    }
    setState(() => _lembretes.removeWhere((l) => l['concluido'] == true));
    await _salvarCacheLocal();
    await _atualizarWidget();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('movidos pro histórico!', style: GoogleFonts.specialElite()),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmarLimparConcluidos() {
    final qtd = _lembretes.where((l) => l['concluido'] == true).length;
    if (qtd == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('nenhum concluído para remover.', style: GoogleFonts.specialElite()),
          backgroundColor: Colors.grey[700],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('limpar concluídos',
            style: GoogleFonts.specialElite(
                color: _txtPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'mover $qtd lembrete${qtd > 1 ? 's' : ''} concluído${qtd > 1 ? 's' : ''} pro histórico?',
          style: GoogleFonts.specialElite(color: _txtSecond),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancelar',
                style: GoogleFonts.specialElite(color: _txtSecond)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _limparConcluidos();
            },
            child: Text('mover',
              style: GoogleFonts.specialElite(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _novoLembrete() async {
    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddReminderScreen()),
    );
    if (resultado != null) {
      final notifId = DateTime.now().millisecondsSinceEpoch % 100000;
      final partes = (resultado['horario'] as String).split(':');

      final lembreteCriado = await LembreteService.adicionarLembrete({
        ...resultado,
        'concluido': false,
      });

      if (lembreteCriado != null) {
        setState(() {
          _lembretes.add(lembreteCriado);
          _ordenar();
        });
        await _salvarCacheLocal();
        await _atualizarWidget();
        await NotificationService().agendarNotificacao(
          id: notifId,
          titulo: resultado['titulo'],
          corpo: 'lembrete: ${resultado['titulo']}',
          hora: int.tryParse(partes[0]) ?? 0,
          minuto: int.tryParse(partes[1]) ?? 0,
          dias: List<String>.from(resultado['dias'] ?? []),
        );
      }
    }
  }

  Future<void> _editarLembrete(int index) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditReminderScreen(
            lembrete: _lembretes[index], index: index),
      ),
    );
    if (resultado == true) await _carregar();
  }

  List<Map<String, dynamic>> get _filtrados {
    return _lembretes.where((l) {
      final passaCat = _categoriaSelecionada == 'Todos' ||
          l['categoria'] == _categoriaSelecionada;
      final concluido = l['concluido'] == true;
      final passaStatus = _statusSelecionado == 'Todos' ||
          (_statusSelecionado == 'Pendentes' && !concluido) ||
          (_statusSelecionado == 'Concluídos' && concluido);
      final titulo = (l['titulo'] as String? ?? '').toLowerCase();
      final passaSearch = _searchQuery.isEmpty ||
          titulo.contains(_searchQuery.toLowerCase());
      return passaCat && passaStatus && passaSearch;
    }).toList();
  }

  int get _total     => _lembretes.length;
  int get _concl     => _lembretes.where((l) => l['concluido'] == true).length;
  int get _pendentes => _total - _concl;

  // ════════════════════════════════════════════════════════
  //  BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: _bgPage,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStats(),
              _buildChipsCategorias(),
              _buildChipsStatus(),
              _buildBarraPesquisa(),
              Expanded(child: _buildLista(_filtrados)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _novoLembrete,
          backgroundColor: _fabBg,
          icon: Icon(Icons.add, color: _fabFg),
          label: Text('novo lembrete',
              style: GoogleFonts.specialElite(color: _fabFg)),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  HEADER
  // ════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 8, 0), // 👈 reduz padding lateral
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── LOGO + BADGE ───
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible( // 👈 deixa o texto encolher
                  child: _isColorido
                      ? ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: _tema.gradiente,
                          ).createShader(bounds),
                          child: Text(
                            'lembrei.',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.specialElite(
                              fontSize: 30, // 👈 36 → 30
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'lembrei.',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.specialElite(
                            fontSize: 30, // 👈 36 → 30
                            fontWeight: FontWeight.bold,
                            color: _temaAtual == AppTema.padrao
                                ? _txtPrimary
                                : _corPrimaria,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                if (_pendentes > 0)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _temaAtual == AppTema.padrao
                          ? Colors.red[500]
                          : _isColorido
                              ? corRainbow(0)
                              : _corPrimaria,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_pendentes',
                      style: GoogleFonts.specialElite(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ─── AÇÕES ───
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_concl > 0)
                SizedBox(
                  width: 32, // 👈 36 → 32
                  height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.delete_sweep_outlined,
                            color: _txtSecond, size: 20),
                        tooltip: 'limpar concluídos',
                        onPressed: _confirmarLimparConcluidos,
                      ),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 13, minHeight: 13),
                          child: Text(
                            '$_concl',
                            style: GoogleFonts.specialElite(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.category_outlined, color: _txtSecond, size: 20),
                tooltip: 'gerenciar categorias',
                onPressed: () async {
                  final alterou = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriasScreen()),
                  );
                  if (alterou == true) {
                    await _carregarCategorias();
                    await _carregar();
                  }
                },
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'escolher tema',
                icon: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _tema.gradiente,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: _txtSecond, width: 1.5),
                  ),
                ),
                onPressed: _abrirSeletorTema,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  _darkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  color: _txtSecond,
                  size: 20,
                ),
                tooltip: _darkMode ? 'modo claro' : 'modo escuro',
                onPressed: _toggleTema,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.bar_chart, color: _txtSecond, size: 22),
                tooltip: 'estatísticas',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EstatisticasScreen(lembretes: _lembretes),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  BOTTOM SHEET — seletor de tema
  // ════════════════════════════════════════════════════════
  void _abrirSeletorTema() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _txtHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'escolha um tema',
                style: GoogleFonts.specialElite(
                  color: _txtPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: appTemas.length,
                itemBuilder: (_, i) {
                  final tema     = AppTema.values[i];
                  final data     = appTemas[tema]!;
                  final selected = tema == _temaAtual;

                  return GestureDetector(
                    onTap: () {
                      _salvarTema(tema);
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: data.gradiente,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: data.primary.withOpacity(0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 22)
                              : Center(
                                  child: Text(
                                    data.emoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.nome,
                          style: GoogleFonts.specialElite(
                            color: selected ? data.primary : _txtSecond,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  STATS
  // ════════════════════════════════════════════════════════
  Widget _buildStats() {
    final pct = _total == 0 ? 0.0 : _concl / _total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('$_total',     'total'),
              _statItem('$_concl',     'concluídos'),
              _statItem('$_pendentes', 'ativos'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: _progressBg,
              valueColor: AlwaysStoppedAnimation<Color>(_progressFg),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(pct * 100).toStringAsFixed(0)}% concluído',
              style: GoogleFonts.specialElite(
                  fontSize: 11, color: _txtSecond),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String valor, String label) {
    return Column(
      children: [
        Text(valor,
            style: GoogleFonts.specialElite(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _txtPrimary)),
        Text(label,
            style: GoogleFonts.specialElite(
                fontSize: 11, color: _txtSecond)),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  BARRA DE PESQUISA
  // ════════════════════════════════════════════════════════
  Widget _buildBarraPesquisa() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.specialElite(color: _txtPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'pesquisar lembrete...',
          hintStyle:
              GoogleFonts.specialElite(color: _txtHint, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: _txtHint, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: _txtHint, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: _bgCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _progressFg),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  CHIPS CATEGORIAS
  // ════════════════════════════════════════════════════════
  Widget _buildChipsCategorias() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categorias.length,
        itemBuilder: (_, i) {
          final cat = _categorias[i];
          final sel = cat == _categoriaSelecionada;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                cat.toLowerCase(),
                style: GoogleFonts.specialElite(
                  color: sel ? Colors.white : _txtSecond,
                  fontSize: 12,
                ),
              ),
              selected: sel,
              selectedColor: _chipCatSelColor(i),
              backgroundColor: _chipUnselBg,
              side: BorderSide(color: _chipBorder),
              onSelected: (_) =>
                  setState(() => _categoriaSelecionada = cat),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  CHIPS STATUS
  // ════════════════════════════════════════════════════════
  Widget _buildChipsStatus() {
    final base = _lembretes.where((l) =>
        _categoriaSelecionada == 'Todos' ||
        l['categoria'] == _categoriaSelecionada);
    final totalCat = base.length;
    final conclCat = base.where((l) => l['concluido'] == true).length;
    final pendCat  = totalCat - conclCat;

    final Map<String, int> contadores = {
      'Todos':      totalCat,
      'Pendentes':  pendCat,
      'Concluídos': conclCat,
    };

    Color corTodos() {
      if (_temaAtual == AppTema.padrao) {
        return _darkMode ? Colors.grey : Colors.black87;
      }
      return _isColorido ? corRainbow(0) : _corPrimaria;
    }

    final Map<String, Color> coresStatus = {
      'Todos':      corTodos(),
      'Pendentes':  Colors.orange,
      'Concluídos': Colors.green,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: _statusOpcoes.map((op) {
          final label = op['label'] as String;
          final icon  = op['icon']  as IconData;
          final sel   = label == _statusSelecionado;
          final cor   = coresStatus[label]!;
          final count = contadores[label]!;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _statusSelecionado = label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? cor : _chipUnselBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? cor : _chipBorder,
                    width: sel ? 2 : 1,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: cor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 16,
                        color: sel ? Colors.white : cor),
                    const SizedBox(height: 2),
                    Text(
                      label.toLowerCase(),
                      style: GoogleFonts.specialElite(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: sel ? Colors.white : _txtSecond,
                      ),
                    ),
                    Text(
                      '$count',
                      style: GoogleFonts.specialElite(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: sel ? Colors.white : cor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  LISTA
  // ════════════════════════════════════════════════════════
  Widget _buildLista(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) {
      final msg = _searchQuery.isNotEmpty
          ? 'nenhum resultado para "$_searchQuery"'
          : _statusSelecionado == 'Pendentes'
              ? 'nenhum lembrete pendente 🎉'
              : _statusSelecionado == 'Concluídos'
                  ? 'nada concluído ainda.'
                  : 'nenhum lembrete aqui.';
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : _statusSelecionado == 'Pendentes'
                      ? Icons.celebration
                      : Icons.inbox_outlined,
              size: 48,
              color: _txtHint,
            ),
            const SizedBox(height: 8),
            Text(msg,
                style: GoogleFonts.specialElite(
                    color: _txtHint, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: lista.length,
      itemBuilder: (_, i) {
        final l = lista[i];
        final indexReal = _lembretes.indexOf(l);
        return _buildCard(l, indexReal);
      },
    );
  }

  // ════════════════════════════════════════════════════════
  //  CARD
  // ════════════════════════════════════════════════════════
  Widget _buildCard(Map<String, dynamic> l, int index) {
    final concluido = l['concluido'] == true;
    final categoria = l['categoria'] as String? ?? 'Outros';
    final cor       = _corCategoria(categoria);
    final icone     = _iconeCategoria(categoria);
    final horario   = l['horario'] as String? ?? '00:00';
    final dias      = List<String>.from(l['dias'] ?? []);
    final atrasado  = _estaAtrasado(l);

    final Color bordaCard = _isColorido && !concluido
        ? corRainbow(_lembretes.indexOf(l))
        : _border;

    return Dismissible(
      key: Key('${l['id']}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deletar(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: concluido ? _bgCardDone : _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: bordaCard,
            width: _isColorido && !concluido ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withOpacity(concluido ? 0.07 : 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone,
                color: concluido ? cor.withOpacity(0.4) : cor,
                size: 22),
          ),
          title: Row(
            children: [
              if (atrasado) ...[
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange[700], size: 18),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  l['titulo'] as String? ?? '',
                  style: GoogleFonts.specialElite(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: concluido
                        ? _txtHint
                        : (atrasado ? Colors.orange[800] : _txtPrimary),
                    decoration:
                        concluido ? TextDecoration.lineThrough : null,
                    decorationColor: _txtHint,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: concluido ? cor.withOpacity(0.4) : cor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoria.toLowerCase(),
                    style: GoogleFonts.specialElite(
                        color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 12,
                        color: concluido ? _txtDisabled : _txtHint),
                    const SizedBox(width: 4),
                    Text(horario,
                        style: GoogleFonts.specialElite(
                            fontSize: 12,
                            color: concluido
                                ? _txtDisabled
                                : _txtSecond)),
                    if (dias.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.repeat,
                          size: 12,
                          color: concluido ? _txtDisabled : _txtHint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dias.join(', ').toLowerCase(),
                          style: GoogleFonts.specialElite(
                              fontSize: 11,
                              color: concluido
                                  ? _txtDisabled
                                  : _txtHint),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!concluido)
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: _txtHint),
                  onPressed: () => _editarLembrete(index),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  visualDensity: VisualDensity.compact,
                ),
              Checkbox(
                value: concluido,
                onChanged: (_) => _toggleConcluido(index),
                activeColor: _temaAtual == AppTema.padrao
                    ? Colors.green
                    : _isColorido
                        ? corRainbow(_lembretes.indexOf(l))
                        : _corPrimaria,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}