import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_service.dart';
import '../services/trash_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _service = CategoryService();
  List<Map<String, dynamic>> _categorias = [];
  bool _alterou = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final cats = await _service.carregar();
    setState(() => _categorias = cats);
  }

  Future<int> _contarLembretes(String nomeCategoria) async {
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString('lembretes');
    if (dados == null) return 0;
    final lista = jsonDecode(dados) as List;
    return lista.where((l) => l['categoria'] == nomeCategoria).length;
  }

  Future<void> _excluirCategoria(int index) async {
    final cat = _categorias[index];
    final nome = cat['nome'] as String;
    final qtd = await _contarLembretes(nome);

    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('excluir "$nome"?',
            style: GoogleFonts.specialElite(fontWeight: FontWeight.bold)),
        content: Text(
          qtd > 0
              ? '$qtd lembrete${qtd > 1 ? 's' : ''} ${qtd > 1 ? 'serão movidos' : 'será movido'} para a lixeira (30 dias).'
              : 'essa categoria não tem lembretes.',
          style: GoogleFonts.specialElite(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancelar', style: GoogleFonts.specialElite()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('excluir',
                style: GoogleFonts.specialElite(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // move lembretes da categoria pra lixeira
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString('lembretes');
    if (dados != null) {
      final lista = (jsonDecode(dados) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final removidos = lista.where((l) => l['categoria'] == nome).toList();
      if (removidos.isNotEmpty) {
        await TrashService().adicionar(removidos);
        lista.removeWhere((l) => l['categoria'] == nome);
        await prefs.setString('lembretes', jsonEncode(lista));
      }
    }

    await _service.excluir(index);
    _alterou = true;
    await _carregar();
  }

  void _abrirEditor({int? index}) {
    final isEdicao = index != null;
    final atual = isEdicao ? _categorias[index] : null;

    final nomeCtrl = TextEditingController(text: atual?['nome'] ?? '');
    IconData iconeSel = isEdicao
        ? CategoryService.iconeFromInt(atual!['icone'])
        : CategoryService.iconesDisponiveis[0];
    Color corSel = isEdicao
        ? CategoryService.corFromInt(atual!['cor'])
        : CategoryService.coresDisponiveis[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  isEdicao ? 'editar categoria' : 'nova categoria',
                  style: GoogleFonts.specialElite(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // preview
                Center(
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: corSel.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconeSel, color: corSel, size: 30),
                  ),
                ),
                const SizedBox(height: 16),

                // nome
                Text('nome', style: GoogleFonts.specialElite(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: nomeCtrl,
                  style: GoogleFonts.specialElite(),
                  decoration: InputDecoration(
                    hintText: 'ex: estudos',
                    hintStyle: GoogleFonts.specialElite(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ícone
                Text('ícone', style: GoogleFonts.specialElite(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: CategoryService.iconesDisponiveis.map((ic) {
                    final sel = ic.codePoint == iconeSel.codePoint;
                    return GestureDetector(
                      onTap: () => setLocal(() => iconeSel = ic),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: sel ? corSel : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel ? corSel : Colors.grey[300]!,
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Icon(ic,
                            color: sel ? Colors.white : Colors.grey[700],
                            size: 22),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // cor
                Text('cor', style: GoogleFonts.specialElite(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: CategoryService.coresDisponiveis.map((c) {
                    final sel = c.value == corSel.value;
                    return GestureDetector(
                      onTap: () => setLocal(() => corSel = c),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel ? Colors.black87 : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: sel
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final nome = nomeCtrl.text.trim();
                      if (nome.isEmpty) return;
                      if (isEdicao) {
                        await _service.editar(index, nome, iconeSel, corSel);
                      } else {
                        await _service.adicionar(nome, iconeSel, corSel);
                      }
                      _alterou = true;
                      if (mounted) Navigator.pop(ctx);
                      await _carregar();
                    },
                    child: Text(
                      isEdicao ? 'salvar' : 'criar',
                      style: GoogleFonts.specialElite(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _alterou);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE8E8E8),
        appBar: AppBar(
          backgroundColor: Colors.black87,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('categorias',
              style: GoogleFonts.specialElite(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: _categorias.isEmpty
            ? Center(
                child: Text('nenhuma categoria.',
                    style: GoogleFonts.specialElite(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categorias.length,
                itemBuilder: (_, i) {
                  final c = _categorias[i];
                  final cor = CategoryService.corFromInt(c['cor']);
                  final icone = CategoryService.iconeFromInt(c['icone']);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: cor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icone, color: cor),
                      ),
                      title: Text(c['nome'],
                          style: GoogleFonts.specialElite(
                              fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined,
                                color: Colors.grey[600], size: 20),
                            onPressed: () => _abrirEditor(index: i),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Colors.red[400], size: 20),
                            onPressed: () => _excluirCategoria(i),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.black87,
          onPressed: () => _abrirEditor(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('nova categoria',
              style: GoogleFonts.specialElite(color: Colors.white)),
        ),
      ),
    );
  }
}