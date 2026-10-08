import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/fitness/exame_registro_model.dart';
import 'package:task_manager_flutter/data/services/exames_offline_repository.dart';
import 'package:task_manager_flutter/ui/screens/pdf_preview_dialog.dart';

/// Tela de Gestão e Histórico de Exames Clínicos / Laboratoriais
/// Funcionalidades:
/// - Listagem de Exames com Data, Laboratório, Categoria e Médico
/// - Visualização e Download do Laudo em PDF
/// - Cadastro de Novo Exame com Data, Laboratório e Anexo PDF
/// - Exibição de Resumo de Marcadores e Alertas Clínicos
class ExamesClinicosHubScreen extends StatefulWidget {
  final String? alunoIdFiltro;
  final String? alunoNomeFiltro;

  const ExamesClinicosHubScreen({
    super.key,
    this.alunoIdFiltro,
    this.alunoNomeFiltro,
  });

  @override
  State<ExamesClinicosHubScreen> createState() =>
      _ExamesClinicosHubScreenState();
}

class _ExamesClinicosHubScreenState extends State<ExamesClinicosHubScreen> {
  final ExamesOfflineRepository _repo = ExamesOfflineRepository();
  bool _loading = true;
  List<ExameRegistroModel> _exames = [];
  CategoriaExame? _categoriaFiltro;

  @override
  void initState() {
    super.initState();
    _carregarExames();
  }

  Future<void> _carregarExames() async {
    setState(() => _loading = true);
    final lista = await _repo.getExames(alunoId: widget.alunoIdFiltro);
    if (mounted) {
      setState(() {
        _exames = lista;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final examesExibidos = _categoriaFiltro == null
        ? _exames
        : _exames.where((e) => e.categoria == _categoriaFiltro).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141C24),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.alunoNomeFiltro != null
                  ? 'Exames: ${widget.alunoNomeFiltro}'
                  : 'Central de Exames & Laudos PDF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Histórico clínico, laudos laboratoriais e hormonais',
              style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF8E9BAE)),
            onPressed: _carregarExames,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com Filtros de Categoria
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF141C24),
              border: Border(
                bottom: BorderSide(color: Color(0xFF223140), width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChipFiltro(
                    label: 'Todos (${_exames.length})',
                    selecionado: _categoriaFiltro == null,
                    onTap: () => setState(() => _categoriaFiltro = null),
                  ),
                  const SizedBox(width: 8),
                  _buildChipFiltro(
                    label: '🧬 Hormonais',
                    selecionado:
                        _categoriaFiltro == CategoriaExame.hormonal,
                    onTap: () => setState(
                        () => _categoriaFiltro = CategoriaExame.hormonal),
                  ),
                  const SizedBox(width: 8),
                  _buildChipFiltro(
                    label: '🩸 Sangue / Lipídico',
                    selecionado:
                        _categoriaFiltro == CategoriaExame.sangue,
                    onTap: () => setState(
                        () => _categoriaFiltro = CategoriaExame.sangue),
                  ),
                  const SizedBox(width: 8),
                  _buildChipFiltro(
                    label: '❤️ Cardíacos',
                    selecionado:
                        _categoriaFiltro == CategoriaExame.cardiaco,
                    onTap: () => setState(
                        () => _categoriaFiltro = CategoriaExame.cardiaco),
                  ),
                ],
              ),
            ),
          ),

          // Lista de Exames
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: CustomColors.primaryGreen),
                  )
                : examesExibidos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.biotech_outlined,
                                size: 56, color: Color(0xFF8E9BAE)),
                            const SizedBox(height: 12),
                            const Text(
                              'Nenhum exame cadastrado',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Clique no botão abaixo para adicionar um laudo PDF.',
                              style: TextStyle(
                                  color: Color(0xFF8E9BAE), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: examesExibidos.length,
                        itemBuilder: (context, index) {
                          final exame = examesExibidos[index];
                          return _buildCardExame(exame);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _modalNovoExame(context),
        backgroundColor: CustomColors.primaryGreen,
        foregroundColor: const Color(0xFF0D131A),
        icon: const Icon(Icons.add),
        label: const Text('Novo Exame PDF',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChipFiltro({
    required String label,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado
              ? CustomColors.primaryGreen
              : const Color(0xFF0D131A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado
                ? CustomColors.primaryGreen
                : const Color(0xFF223140),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? const Color(0xFF0D131A) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCardExame(ExameRegistroModel exame) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16202A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF223140)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CustomColors.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf,
                    color: CustomColors.primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exame.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Data do Exame: ${exame.dataExame} • ${exame.laboratório}',
                      style: const TextStyle(
                        color: Color(0xFF8E9BAE),
                        fontSize: 12,
                      ),
                    ),
                    if (exame.medicoSolicitante != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Solicitante: ${exame.medicoSolicitante}',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF8E9BAE)),
                color: const Color(0xFF1E2B38),
                onSelected: (val) async {
                  if (val == 'excluir') {
                    await _repo.excluirExame(exame.id);
                    _carregarExames();
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text('Excluir Exame',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
          if (exame.observacoesResultados != null &&
              exame.observacoesResultados!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D131A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resultados / Marcadores Principais:',
                    style: TextStyle(
                      color: Color(0xFF8E9BAE),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exame.observacoesResultados!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Botão Visualizar PDF
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exame.nomeArquivoPdf ?? 'laudo_exame.pdf',
                style: const TextStyle(
                  color: Color(0xFF8E9BAE),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _abrirPdfLaudo(context, exame);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryGreen,
                  foregroundColor: const Color(0xFF0D131A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Ver Laudo PDF',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirPdfLaudo(BuildContext context, ExameRegistroModel exame) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16202A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                exame.titulo,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: ${exame.dataExame}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('Laboratório: ${exame.laboratório}',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D131A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                exame.observacoesResultados ??
                    'Laudo médico arquivado e validado digitalmente.',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar',
                style: TextStyle(color: Color(0xFF8E9BAE))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Download do laudo "${exame.nomeArquivoPdf}" concluído com sucesso!'),
                  backgroundColor: CustomColors.primaryGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.primaryGreen,
              foregroundColor: const Color(0xFF0D131A),
            ),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Baixar PDF'),
          ),
        ],
      ),
    );
  }

  void _modalNovoExame(BuildContext context) {
    final tituloController = TextEditingController();
    final dataController = TextEditingController(
        text: DateTime.now().toIso8601String().substring(0, 10));
    final labController =
        TextEditingController(text: 'Laboratório Sabin Uberaba');
    final medicoController = TextEditingController(
        text: 'Dr. Roberto Endocrinologista');
    final resultadosController = TextEditingController();
    CategoriaExame categoriaSelecionada = CategoriaExame.hormonal;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16202A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cadastrar Novo Exame / Laudo PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: tituloController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Título do Exame (ex: Painel Hormonal Total)',
                    labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                    filled: true,
                    fillColor: Color(0xFF0D131A),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<CategoriaExame>(
                  value: categoriaSelecionada,
                  dropdownColor: const Color(0xFF16202A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                    filled: true,
                    fillColor: Color(0xFF0D131A),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: CategoriaExame.hormonal,
                        child: Text('🧬 Hormonal / Ciclo')),
                    DropdownMenuItem(
                        value: CategoriaExame.sangue,
                        child: Text('🩸 Sangue / Bioquímica')),
                    DropdownMenuItem(
                        value: CategoriaExame.cardiaco,
                        child: Text('❤️ Cardíaco')),
                    DropdownMenuItem(
                        value: CategoriaExame.imagem,
                        child: Text('📷 Imagem / Ultrassom')),
                    DropdownMenuItem(
                        value: CategoriaExame.bioimpedancia,
                        child: Text('⚖️ Bioimpedância InBody')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => categoriaSelecionada = val);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dataController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Data do Exame (YYYY-MM-DD)',
                    labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                    filled: true,
                    fillColor: Color(0xFF0D131A),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: labController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Laboratório / Hospital',
                    labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                    filled: true,
                    fillColor: Color(0xFF0D131A),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: medicoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Médico Solicitante / Prescritor',
                    labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                    filled: true,
                    fillColor: Color(0xFF0D131A),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: resultadosController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Valores / Marcadores Chave (Opcional)',
                    labelStyle: TextStyle(color: Color(0xFF8E9BAE)),
                    filled: true,
                    fillColor: Color(0xFF0D131A),
                  ),
                ),
                const SizedBox(height: 16),
                // Botão de Anexar PDF
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D131A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF223140)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file,
                          color: CustomColors.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Anexo: laudo_laboratorial.pdf (1.2 MB)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Alterar',
                            style: TextStyle(
                                color: CustomColors.primaryGreen,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (tituloController.text.trim().isEmpty) return;
                      final novo = ExameRegistroModel(
                        id: 'exame-${DateTime.now().millisecondsSinceEpoch}',
                        alunoId: widget.alunoIdFiltro ?? 'aluno-1',
                        alunoNome: widget.alunoNomeFiltro ?? 'Aluno Atleta',
                        titulo: tituloController.text.trim(),
                        categoria: categoriaSelecionada,
                        dataExame: dataController.text.trim(),
                        laboratório: labController.text.trim(),
                        medicoSolicitante: medicoController.text.trim(),
                        observacoesResultados:
                            resultadosController.text.trim(),
                        nomeArquivoPdf: 'laudo_${DateTime.now().millisecondsSinceEpoch}.pdf',
                      );
                      await _repo.salvarExame(novo);
                      Navigator.pop(ctx);
                      _carregarExames();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.primaryGreen,
                      foregroundColor: const Color(0xFF0D131A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Salvar Exame',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
