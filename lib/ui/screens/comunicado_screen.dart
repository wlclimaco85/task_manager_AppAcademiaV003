import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/comunicados_model.dart';
import 'package:task_manager_flutter/data/services/comunicado_caller.dart';
import 'package:task_manager_flutter/data/models/setor_model.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/data/services/setor_caller.dart';

class ComunicadoScreen extends StatefulWidget {
  const ComunicadoScreen({super.key});

  @override
  State<ComunicadoScreen> createState() => _ComunicadoScreenState();
}

class _ComunicadoScreenState extends State<ComunicadoScreen> {
  final ComunicadoCaller _caller = ComunicadoCaller();
  final SetorCaller _setorCaller = SetorCaller();
  List<Comunicado> _comunicados = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComunicados();
  }

  Future<void> _loadComunicados() async {
    setState(() => _isLoading = true);
    _comunicados = await _caller.fetchAllComunicados();
    setState(() => _isLoading = false);
  }

  Future<void> _showComunicadoForm({Comunicado? comunicado}) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController tituloCtrl =
        TextEditingController(text: comunicado?.titulo ?? '');
    final TextEditingController conteudoCtrl =
        TextEditingController(text: comunicado?.conteudo ?? '');
    final TextEditingController autorCtrl =
        TextEditingController(text: comunicado?.autor ?? '');
    List<Map<String, dynamic>> setores = await Comunicado.loadSetoresDropdown();
    int? setorSelecionado = comunicado?.setor?.id;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: Text(
          comunicado == null ? "Novo Comunicado" : "Editar Comunicado",
          style:
              const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: "Título",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Informe o título" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: conteudoCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Conteúdo",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Informe o conteúdo" : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: setorSelecionado,
                  items: setores
                      .map(
                        (e) => DropdownMenuItem<int>(
                          value: e['value'],
                          child: Text(e['label']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setorSelecionado = v,
                  decoration: const InputDecoration(
                    labelText: "Setor",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (v) => v == null ? "Selecione um setor" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: autorCtrl,
                  decoration: const InputDecoration(
                    labelText: "Autor",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Informe o autor" : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Salvar"),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final novo = Comunicado(
                  id: comunicado?.id,
                  titulo: tituloCtrl.text,
                  conteudo: conteudoCtrl.text,
                  autor: autorCtrl.text,
                  setor: Setor(id: setorSelecionado, nome: ""),
                  dataPublicacao: DateTime.now(),
                  dhCreatedAt: DateTime.now(),
                );
                bool ok = comunicado == null
                    ? await _caller.createComunicado(novo)
                    : await _caller.updateComunicado(novo);
                if (ok) {
                  Navigator.pop(context);
                  _loadComunicados();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text("Comunicado salvo com sucesso!"),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Erro ao salvar comunicado"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Comunicado c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Comunicado"),
        content: const Text("Deseja realmente excluir este comunicado?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancelar", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _caller.deleteComunicado(c.id!);
              _loadComunicados();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text("Comunicado excluído com sucesso!"),
                ),
              );
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[900],
      appBar: UserBannerAppBar(
        screenTitle: "Comunicados",
        isLoading: _isLoading,
        showFilterButton: false,
        onRefresh: _loadComunicados,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _comunicados.isEmpty
              ? const Center(
                  child: Text(
                    "Nenhum comunicado disponível",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: _comunicados.length,
                  itemBuilder: (context, i) {
                    final c = _comunicados[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.red, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(c.titulo ?? "Sem título",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          c.conteudo ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () =>
                                  _showComunicadoForm(comunicado: c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botão de refresh
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.red, width: 2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "refreshBtn",
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              elevation: 0,
              onPressed: _loadComunicados,
              child: const Icon(Icons.refresh),
            ),
          ),
          // Botão de adicionar comunicado
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.red, width: 2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "addBtn",
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              elevation: 0,
              onPressed: () => _showComunicadoForm(),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
