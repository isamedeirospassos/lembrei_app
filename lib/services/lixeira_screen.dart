import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/trash_service.dart';

class LixeiraScreen extends StatefulWidget {
  const LixeiraScreen({super.key});

  @override
  State<LixeiraScreen> createState() => _LixeiraScreenState();
}

class _LixeiraScreenState extends State<LixeiraScreen> {
  final _trash = TrashService();
  List<Map<String, dynamic>> _itens = [];
  bool _alterou = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final lista = await _trash.carregar();
    setState(() => _itens = lista);
  }

  Future<void> _restaurar(int index) async {
    final l = await _trash.restaurar(index);
    if (l == null) return;

    // adiciona de volta na lista de lembretes
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString('lembretes');
    final lista = dados != null
        ? (jsonDecode(dados) as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    lista.add(l);
    await prefs.setString('lembretes', jsonEncode(lista));

    _alterou = true;
    await _carregar();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('lembrete restaurado!',
            style: GoogleFonts.specialElite()),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _excluirDef(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('excluir definitivamente?',
            style: GoogleFonts.specialElite(fontWeight: FontWeight.bold)),
        content: Text('essa ação não pode ser desfeita.',
            style: GoogleFonts.specialElite()),
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
    await _trash.excluirDefinitivo(index);
    await _carregar();
  }

  Future<void> _esvaziar() async {
    if (_itens.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('esvaziar lixeira?',
            style: GoogleFonts.specialElite(fontWeight: FontWeight.bold)),
        content: Text(
          'remover ${_itens.length} ite${_itens.length > 1 ? "ns" : "m"} permanentemente?',
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
            child: Text('esvaziar',
                style: GoogleFonts.specialElite(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _trash.esvaziar();
    await _carregar();
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
          title: Text('lixeira',
              style: GoogleFonts.specialElite(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            if (_itens.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                tooltip: 'esvaziar',
                onPressed: _esvaziar,
              ),
          ],
        ),
        body: _itens.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('lixeira vazia',
                        style: GoogleFonts.specialElite(
                            color: Colors.grey[600], fontSize: 16)),
                  ],
                ),
              )
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.amber[100],
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: Colors.amber[900]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'itens são removidos após 30 dias',
                            style: GoogleFonts.specialElite(
                                fontSize: 12, color: Colors.amber[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _itens.length,
                      itemBuilder: (_, i) {
                        final l = _itens[i];
                        final dias = TrashService.diasRestantes(l);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ListTile(
                            title: Text(
                              l['titulo'] ?? '',
                              style: GoogleFonts.specialElite(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${l['categoria'] ?? ""} • restam $dias dia${dias != 1 ? "s" : ""}',
                              style: GoogleFonts.specialElite(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.restore,
                                      color: Colors.green[700], size: 22),
                                  tooltip: 'restaurar',
                                  onPressed: () => _restaurar(i),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_forever,
                                      color: Colors.red[400], size: 22),
                                  tooltip: 'excluir',
                                  onPressed: () => _excluirDef(i),
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