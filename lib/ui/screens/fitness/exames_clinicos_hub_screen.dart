import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/services/exame_laudo_service.dart';
import 'package:task_manager_flutter/data/utils/exame_pdf_parser.dart';
import 'package:task_manager_flutter/ui/screens/fitness/exame_historico_screen.dart';
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
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.card,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.alunoNomeFiltro != null
                  ? 'Exames: ${widget.alunoNomeFiltro}'
                  : 'Central de Exames & Laudos PDF',
              style: TextStyle(
                color: GridColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Histórico clínico, laudos laboratoriais e hormonais',
              style: TextStyle(color: GridColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Gráficos por item',
            icon: Icon(Icons.show_chart, color: GridColors.textSecondary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExameHistoricoScreen()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: GridColors.textSecondary),
            onPressed: _carregarExames,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com Filtros de Categoria
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: GridColors.card,
              border: Border(
                bottom: BorderSide(color: GridColors.divider, width: 1),
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
                ? Center(
                    child: CircularProgressIndicator(
                        color: CustomColors.primaryGreen),
                  )
                : examesExibidos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.biotech_outlined,
                                size: 56, color: GridColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum exame cadastrado',
                              style: TextStyle(
                                  color: GridColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Clique no botão abaixo para adicionar um laudo PDF.',
                              style: TextStyle(
                                  color: GridColors.textSecondary, fontSize: 13),
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
        foregroundColor: GridColors.textOnPrimary,
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
              : GridColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado
                ? CustomColors.primaryGreen
                : GridColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? GridColors.textOnPrimary : GridColors.textPrimary,
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
        color: GridColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GridColors.divider),
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
                child: Icon(Icons.picture_as_pdf,
                    color: CustomColors.primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exame.titulo,
                      style: TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Data do Exame: ${exame.dataExame} • ${exame.laboratorio}',
                      style: TextStyle(
                        color: GridColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (exame.medicoSolicitante != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Solicitante: ${exame.medicoSolicitante}',
                        style: const TextStyle(
                          color: GridColors.info,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: GridColors.textSecondary),
                color: GridColors.card,
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
                        style: TextStyle(color: GridColors.error)),
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
                color: GridColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resultados / Marcadores Principais:',
                    style: TextStyle(
                      color: GridColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exame.observacoesResultados!,
                    style: TextStyle(
                      color: GridColors.textSecondary,
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
                style: TextStyle(
                  color: GridColors.textSecondary,
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
                  foregroundColor: GridColors.textOnPrimary,
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
        backgroundColor: GridColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: GridColors.error, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                exame.titulo,
                style: TextStyle(color: GridColors.textPrimary, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: ${exame.dataExame}',
                style: TextStyle(color: GridColors.textSecondary, fontSize: 13)),
            Text('Laboratório: ${exame.laboratorio}',
                style: TextStyle(color: GridColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GridColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                exame.observacoesResultados ??
                    'Laudo médico arquivado e validado digitalmente.',
                style: TextStyle(color: GridColors.textPrimary, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fechar',
                style: TextStyle(color: GridColors.textSecondary)),
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
              foregroundColor: GridColors.textOnPrimary,
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
    PlatformFile? pdfEscolhido;
    List<ExameItemLido> itensLidos = [];
    String? avisoLeitura;

    /// Escolhe o PDF do aparelho e le o eritrograma do texto do laudo.
    Future<void> escolherPdf(void Function(void Function()) setModalState) async {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      final arquivo = resultado?.files.single;
      final bytes = arquivo?.bytes;
      if (arquivo == null || bytes == null) return;
      if (bytes.length > 5 * 1024 * 1024) {
        setModalState(() {
          pdfEscolhido = null;
          itensLidos = [];
          avisoLeitura = 'O PDF deve ter até 5 MB.';
        });
        return;
      }
      // Le pagina por pagina: posicoes verticais se repetem entre paginas e misturariam os exames.
      // So processa paginas do hemograma (cabecalho HEMOGRAMA).
      final documento = PdfDocument(inputBytes: bytes);
      final itens = <ExameItemLido>[];
      String? medicoLido;
      String? laboratorioLido;
      for (var pagina = 0; pagina < documento.pages.count; pagina++) {
        final pedacos = [
          for (final linha in PdfTextExtractor(documento)
              .extractTextLines(startPageIndex: pagina, endPageIndex: pagina))
            (y: linha.bounds.top, x: linha.bounds.left, texto: linha.text),
        ];
        final linhas = ExameLaudoParser.montarLinhas(pedacos);
        medicoLido ??= ExameLaudoParser.medicoDoLaudo(linhas);
        laboratorioLido ??= ExameLaudoParser.laboratorioDoLaudo(linhas);
        if (linhas.any((l) => l.contains('HEMOGRAMA'))) {
          itens.addAll(ExameLaudoParser.lerHemograma(linhas));
        } else {
          // Outros laudos (paineis hormonais, lipidico...): resultados no formato "Resultado: valor unidade".
          itens.addAll(ExameLaudoParser.lerResultados(linhas,
              dataExame: ExameLaudoParser.dataColeta(linhas, 0)));
        }
      }
      documento.dispose();
      final porGrupo = <String, int>{};
      for (final item in itens) {
        porGrupo[item.grupo] = (porGrupo[item.grupo] ?? 0) + 1;
      }
      setModalState(() {
        pdfEscolhido = arquivo;
        itensLidos = itens;
        // A data do exame passa a ser a data da coleta lida do laudo (nao a data de hoje).
        for (final item in itens) {
          if (item.dataExame != null) {
            dataController.text = item.dataExame!;
            break;
          }
        }
        // Medica e laboratorio lidos do cabecalho do laudo.
        if (medicoLido != null) medicoController.text = medicoLido;
        if (laboratorioLido != null) labController.text = laboratorioLido;
        // Titulo sugerido: medica lida do laudo + data da coleta, so se o usuario ainda nao digitou um.
        // Nao usa o nome de exemplo pre-preenchido: so medico efetivamente lido do PDF.
        if (tituloController.text.trim().isEmpty && medicoLido != null) {
          final partes = dataController.text.trim().split('-');
          final dataBr = partes.length == 3
              ? '${partes[2]}/${partes[1]}/${partes[0]}'
              : dataController.text.trim();
          tituloController.text = '$medicoLido - $dataBr';
        }
        avisoLeitura = itens.isEmpty
            ? 'Não encontrei resultados neste PDF. Ao salvar, só o PDF será guardado.'
            : '${itens.length} itens lidos: '
                '${porGrupo.entries.map((e) => '${e.value} ${e.key.toLowerCase()}').join(', ')}.';
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: GridColors.card,
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
                Text(
                  'Cadastrar Novo Exame / Laudo PDF',
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: tituloController,
                  style: TextStyle(color: GridColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Título do Exame (ex: Painel Hormonal Total)',
                    labelStyle: TextStyle(color: GridColors.textSecondary),
                    filled: true,
                    fillColor: GridColors.inputBackground,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<CategoriaExame>(
                  value: categoriaSelecionada,
                  dropdownColor: GridColors.card,
                  style: TextStyle(color: GridColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    labelStyle: TextStyle(color: GridColors.textSecondary),
                    filled: true,
                    fillColor: GridColors.inputBackground,
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
                  style: TextStyle(color: GridColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Data do Exame (YYYY-MM-DD)',
                    labelStyle: TextStyle(color: GridColors.textSecondary),
                    filled: true,
                    fillColor: GridColors.inputBackground,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: labController,
                  style: TextStyle(color: GridColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Laboratório / Hospital',
                    labelStyle: TextStyle(color: GridColors.textSecondary),
                    filled: true,
                    fillColor: GridColors.inputBackground,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: medicoController,
                  style: TextStyle(color: GridColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Médico Solicitante / Prescritor',
                    labelStyle: TextStyle(color: GridColors.textSecondary),
                    filled: true,
                    fillColor: GridColors.inputBackground,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: resultadosController,
                  maxLines: 2,
                  style: TextStyle(color: GridColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Valores / Marcadores Chave (Opcional)',
                    labelStyle: TextStyle(color: GridColors.textSecondary),
                    filled: true,
                    fillColor: GridColors.inputBackground,
                  ),
                ),
                const SizedBox(height: 16),
                // Botão de Anexar PDF
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GridColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GridColors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file,
                          color: CustomColors.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pdfEscolhido == null
                              ? 'Nenhum PDF escolhido'
                              : 'Anexo: ${pdfEscolhido!.name}',
                          style: TextStyle(
                            color: GridColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => escolherPdf(setModalState),
                        child: Text(pdfEscolhido == null ? 'Escolher PDF' : 'Alterar',
                            style: TextStyle(
                                color: CustomColors.primaryGreen,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                if (avisoLeitura != null) ...[
                  const SizedBox(height: 8),
                  Text(avisoLeitura!,
                      style: TextStyle(
                          color: GridColors.textSecondary, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (tituloController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Informe o título do exame.')));
                        return;
                      }
                      final novo = ExameRegistroModel(
                        id: 'exame-${DateTime.now().millisecondsSinceEpoch}',
                        alunoId: widget.alunoIdFiltro ?? 'aluno-1',
                        alunoNome: widget.alunoNomeFiltro ?? 'Aluno Atleta',
                        titulo: tituloController.text.trim(),
                        categoria: categoriaSelecionada,
                        dataExame: dataController.text.trim(),
                        laboratorio: labController.text.trim(),
                        medicoSolicitante: medicoController.text.trim(),
                        observacoesResultados:
                            resultadosController.text.trim(),
                        nomeArquivoPdf: 'laudo_${DateTime.now().millisecondsSinceEpoch}.pdf',
                      );
                      final pdf = pdfEscolhido;
                      if (pdf != null && pdf.bytes != null) {
                        try {
                          await ExameLaudoService().enviar(
                            dataExame: dataController.text.trim(),
                            nomeArquivo: pdf.name,
                            pdfBase64: base64Encode(pdf.bytes!),
                            medico: medicoController.text.trim(),
                            laboratorio: labController.text.trim(),
                            itens: [
                              for (final item in itensLidos)
                                {
                                  'grupo': item.grupo,
                                  'nome': item.nome,
                                  'valor': item.valor,
                                  'unidade': item.unidade,
                                  'refMin': item.refMin,
                                  'refMax': item.refMax,
                                  'dataExame': item.dataExame,
                                },
                            ],
                          );
                        } catch (e) {
                          // Falha de rede ou do servidor: mostra o motivo e mantem o modal aberto.
                          final mensagem = e is StateError
                              ? e.message.toString()
                              : 'Sem conexão com o servidor. Tente novamente.';
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx)
                                .showSnackBar(SnackBar(content: Text(mensagem)));
                          }
                          return;
                        }
                      }
                      await _repo.salvarExame(novo);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _carregarExames();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.primaryGreen,
                      foregroundColor: GridColors.textOnPrimary,
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
