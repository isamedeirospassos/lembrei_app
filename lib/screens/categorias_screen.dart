import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/category_service.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _service = CategoryService();
  List<Map<String, dynamic>> _categorias = [];
  bool _darkMode = false;
  bool _alterou = false;

  @override
  void initState() {
    super.initState();
    _carregarTema();
    _carregar();
  }

  Future<void> _carregarTema() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _carregar() async {
    final categorias = await _service.carregar();
    setState(() {
      _categorias = categorias;
    });
  }

  Future<void> _adicionarOuEditar({int? index}) async {
    final categoria = index != null ? _categorias[index] : null;
    final nomeController = TextEditingController(text: categoria?['nome'] ?? '');
    Color corSelecionada = categoria != null
        ? Color(categoria['cor'])
        : CategoryService.coresDisponiveis.first;
    IconData iconeSelecionado = categoria != null
        ? CategoryService.iconeFromInt(categoria['icone'])
        : CategoryService.iconesDisponiveis.first;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            categoria == null ? 'Nova Categoria' : 'Editar Categoria',
            style: GoogleFonts.poppins(
              color: _darkMode ? Colors.white : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeController,
                  style: TextStyle(
                    color: _darkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    labelStyle: TextStyle(
                      color: _darkMode ? Colors.white70 : Colors.black54,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _darkMode ? Colors.white24 : Colors.black26,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: corSelecionada),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cor',
                  style: GoogleFonts.poppins(
                    color: _darkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryService.coresDisponiveis.map((cor) {
                    final selecionada = cor.value == corSelecionada.value;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => corSelecionada = cor),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selecionada
                                ? (_darkMode ? Colors.white : Colors.black)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ícone',
                  style: GoogleFonts.poppins(
                    color: _darkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryService.iconesDisponiveis.map((icone) {
                    final selecionado =
                        icone.codePoint == iconeSelecionado.codePoint;
                    return GestureDetector(
                      onTap: () =>
                          setStateDialog(() => iconeSelecionado = icone),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selecionado
                              ? corSelecionada.withOpacity(0.3)
                              : (_darkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selecionado
                                ? corSelecionada
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icone,
                          color: _darkMode ? Colors.white : Colors.black87,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: _darkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: corSelecionada),
              onPressed: () {
                if (nomeController.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (resultado == true) {
      if (index == null) {
        await _service.adicionar(
          nomeController.text.trim(),
          iconeSelecionado,
          corSelecionada,
        );
      } else {
        await _service.editar(
          index,
          nomeController.text.trim(),
          iconeSelecionado,
          corSelecionada,
        );
      }
      _alterou = true;
      _carregar();
    }
  }

  Future<void> _excluir(int index) async {
    final categoria = _categorias[index];
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          'Excluir categoria',
          style: GoogleFonts.poppins(
            color: _darkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Deseja excluir "${categoria['nome']}"?',
          style: TextStyle(
            color: _darkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: _darkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirma == true) {
      await _service.excluir(index);
      _alterou = true;
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _alterou);
        return false;
      },
      child: Scaffold(
        backgroundColor: _darkMode ? Colors.black : Colors.grey[100],
        appBar: AppBar(
          backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
          elevation: 0,
          iconTheme:
              IconThemeData(color: _darkMode ? Colors.white : Colors.black),
          title: Text(
            'Categorias',
            style: GoogleFonts.poppins(
              color: _darkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _alterou),
          ),
        ),
        body: _categorias.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 64,
                      color: _darkMode ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma categoria',
                      style: GoogleFonts.poppins(
                        color: _darkMode ? Colors.white54 : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categorias.length,
                itemBuilder: (context, index) {
                  final c = _categorias[index];
                  final cor = Color(c['cor']);
                  final icone = CategoryService.iconeFromInt(c['icone']);
                  return Card(
                    color: _darkMode ? Colors.grey[900] : Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icone, color: cor),
                      ),
                      title: Text(
                        c['nome'],
                        style: GoogleFonts.poppins(
                          color: _darkMode ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color:
                                  _darkMode ? Colors.white70 : Colors.black54,
                            ),
                            onPressed: () =>
                                _adicionarOuEditar(index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _excluir(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: () => _adicionarOuEditar(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}