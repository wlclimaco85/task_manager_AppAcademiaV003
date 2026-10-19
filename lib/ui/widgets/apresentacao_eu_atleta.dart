import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_manager_flutter/ui/widgets/versao_app_label.dart';
import 'package:task_manager_flutter/data/utils/app_logger.dart';

/// Apresentação pública. Capturas de demonstração são assets e não criam
/// registros nem entram no armazenamento das contas.
class ApresentacaoEuAtleta extends StatefulWidget {
  final Widget login;
  final VoidCallback onCriarConta;
  final String? pixCopiaCola;
  final Widget? pixQr;
  const ApresentacaoEuAtleta({
    super.key,
    required this.login,
    required this.onCriarConta,
    this.pixCopiaCola = const String.fromEnvironment('DONATION_PIX_CODE'),
    this.pixQr,
  });

  @override
  State<ApresentacaoEuAtleta> createState() => _ApresentacaoEuAtletaState();
}

class _ApresentacaoEuAtletaState extends State<ApresentacaoEuAtleta> {
  static const _fundo = Color(0xFF080F0D);
  static const _painel = Color(0xFF101C17);
  static const _verde = Color(0xFF55E69D);
  static const _muted = Color(0xFFB8C9BF);
  static const _linha = Color(0xFF24362D);
  final _loginKey = GlobalKey();
  final _recursosKey = GlobalKey();
  final _apoioKey = GlobalKey();

  void _irPara(GlobalKey key) {
    FocusScope.of(context).unfocus();
    final destino = key.currentContext;
    if (destino == null) return;
    Scrollable.ensureVisible(destino,
        alignment: 0.05,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic);
  }

  Future<void> _copiarPix() async {
    final codigo = widget.pixCopiaCola?.trim() ?? '';
    if (codigo.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: codigo));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Código Pix copiado.'),
          backgroundColor: Color(0xFF059669)));
    } catch (e, st) {
      AppLogger.i.error('Falha ao copiar código Pix de apoio: $e', st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Não foi possível copiar. Você pode selecionar o código abaixo.')));
      }
    }
  }

  Text _texto(String valor,
          {double tamanho = 16,
          Color cor = Colors.white,
          FontWeight peso = FontWeight.w400,
          double altura = 1.6}) =>
      Text(valor,
          style: TextStyle(
              fontSize: tamanho, color: cor, fontWeight: peso, height: altura));

  Widget _etiqueta(String texto) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: _verde.withValues(alpha: 0.08),
            border: Border.all(color: _verde.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(30)),
        child: Text(texto,
            style: const TextStyle(
                color: _verde,
                fontSize: 11,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700)),
      );

  Widget _botaoCriar({String texto = 'Criar conta grátis'}) =>
      FilledButton.icon(
        onPressed: widget.onCriarConta,
        icon: const Icon(Icons.arrow_forward_rounded, size: 19),
        iconAlignment: IconAlignment.end,
        style: FilledButton.styleFrom(
            backgroundColor: _verde,
            foregroundColor: _fundo,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        label: Text(texto),
      );

  Widget _cabecalho(bool largo) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(children: [
          Expanded(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: _verde, borderRadius: BorderRadius.circular(10)),
                child:
                    const Icon(Icons.fitness_center, color: _fundo, size: 20)),
            const SizedBox(width: 10),
            const Text('EU ATLETA',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7)),
          ])),
          if (largo) ...[
            TextButton(
                onPressed: () => _irPara(_recursosKey),
                child: const Text('Recursos', style: TextStyle(color: _muted))),
            TextButton(
                onPressed: () => _irPara(_apoioKey),
                child: const Text('Apoie o projeto',
                    style: TextStyle(color: _muted))),
            const SizedBox(width: 16),
          ],
          TextButton(
              onPressed: () => _irPara(_loginKey),
              child: const Text('Entrar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700))),
          if (largo) ...[
            const SizedBox(width: 12),
            _botaoCriar(texto: 'Começar grátis')
          ],
        ]),
      );

  Widget _heroTexto(bool largo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _etiqueta('APP + SITE • GRATUITOS'),
          const SizedBox(height: 24),
          Text.rich(
              const TextSpan(children: [
                TextSpan(text: 'Seu treino.\n'),
                TextSpan(
                    text: 'Sua evolução.\n', style: TextStyle(color: _verde)),
                TextSpan(text: 'No seu ritmo.'),
              ]),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: largo ? 66 : 43,
                  height: 1.06,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2)),
          const SizedBox(height: 24),
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _texto(
                  'Monte sua ficha, registre cada série e acompanhe seu progresso. '
                  'Um lugar para organizar a rotina de quem treina e de quem orienta.',
                  tamanho: 17,
                  cor: _muted)),
          const SizedBox(height: 28),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _botaoCriar(),
            OutlinedButton(
                onPressed: () => _irPara(_recursosKey),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    side: const BorderSide(color: _linha),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('Conhecer o Eu Atleta')),
          ]),
          const SizedBox(height: 28),
          Wrap(spacing: 20, runSpacing: 10, children: [
            for (final item in [
              'Treino offline',
              'Histórico completo',
              'Sem mensalidade'
            ])
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_outline, size: 16, color: _verde),
                const SizedBox(width: 6),
                _texto(item, tamanho: 12, cor: _muted),
              ]),
          ]),
        ],
      );

  Widget _login() => Container(
        key: _loginKey,
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FBF9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 36,
                  offset: const Offset(0, 16))
            ]),
        child: widget.login,
      );

  Widget _titulo(String chamada, String titulo, String descricao, bool largo) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(chamada,
            style: const TextStyle(
                color: _verde,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6)),
        const SizedBox(height: 14),
        _texto(titulo,
            tamanho: largo ? 38 : 29, peso: FontWeight.w800, altura: 1.18),
        const SizedBox(height: 14),
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 710),
            child: _texto(descricao, cor: _muted, tamanho: 15)),
      ]);

  Widget _recurso(IconData icon, String titulo, String descricao) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: _painel,
            border: Border.all(color: _linha),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _verde.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: _verde, size: 23)),
          const SizedBox(height: 20),
          _texto(titulo, tamanho: 18, peso: FontWeight.w700, altura: 1.3),
          const SizedBox(height: 10),
          _texto(descricao, tamanho: 14, cor: _muted),
        ]),
      );

  Widget _recursos(bool largo, double largura) {
    final colunas = largo
        ? 3
        : largura >= 600
            ? 2
            : 1;
    final itemLargura = (largura - (colunas - 1) * 16) / colunas;
    return Column(
        key: _recursosKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo(
              'UMA ROTINA MAIS ORGANIZADA',
              'Do primeiro treino à próxima conquista.',
              'Registre o que você faz. Volte ao seu histórico. Use os dados da sua rotina '
                  'para acompanhar a evolução, com ou sem personal.',
              largo),
          const SizedBox(height: 28),
          Wrap(spacing: 16, runSpacing: 16, children: [
            for (final recurso in [
              (
                Icons.fitness_center,
                'Sua ficha, do seu jeito',
                'Organize a ordem dos exercícios, séries, repetições, cargas e alternativas para quando o aparelho estiver ocupado.'
              ),
              (
                Icons.wifi_off_rounded,
                'Continue mesmo offline',
                'Registre o treino no aparelho sem conexão. As alterações pendentes sincronizam quando a internet volta.'
              ),
              (
                Icons.history_rounded,
                'Seu histórico tem detalhes',
                'Consulte as séries e cargas realizadas, anote como foi o treino e guarde até 3 fotos e 3 links de vídeos por sessão.'
              ),
              (
                Icons.insights_rounded,
                'Evolução que você acompanha',
                'Veja gráficos de peso, desempenho e quantidade de treinos a partir dos seus próprios registros.'
              ),
              (
                Icons.restaurant_outlined,
                'Cuide da sua rotina',
                'Organize refeições, suplementos, medidas e metas com as informações que você cadastra.'
              ),
              (
                Icons.groups_outlined,
                'Também para personal',
                'Vincule seus alunos, monte fichas e acompanhe o histórico de quem treina com você.'
              ),
              (
                Icons.monitor_heart_outlined,
                'Avaliação física',
                'Registre avaliações físicas e acompanhe a evolução do seu corpo ao longo do tempo.'
              ),
              (
                Icons.person_search_outlined,
                'Contrate um personal',
                'Encontre personais disponíveis, veja onde atendem e contrate direto pelo app.'
              ),
              (
                Icons.ondemand_video_outlined,
                'Vídeos nos exercícios',
                'O personal vincula vídeos do YouTube ou Google Drive às explicações de cada exercício.'
              ),
              (
                Icons.medication_outlined,
                'Cadastro de suplementos',
                'Cadastre seus suplementos e acompanhe a sua rotina de uso.'
              ),
            ])
              SizedBox(
                  width: itemLargura,
                  child: _recurso(recurso.$1, recurso.$2, recurso.$3)),
          ]),
        ]);
  }

  void _ampliarCaptura(String asset, String titulo) {
    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('$titulo • demonstração'),
      content: SizedBox(width: 1000, child: SingleChildScrollView(
        child: Image.asset(asset, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text('Prévia indisponível.')))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Fechar'))],
    ));
  }

  Widget _captura(String asset, String titulo, String descricao) => Container(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        decoration: BoxDecoration(
            color: _painel,
            border: Border.all(color: _linha),
            borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
              child: Container(
            height: 420,
            constraints: const BoxConstraints(maxWidth: 265),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0xFF020604),
                border: Border.all(color: const Color(0xFF33463B), width: 2),
                borderRadius: BorderRadius.circular(24)),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(asset,
                    fit: BoxFit.contain,
                    semanticLabel: 'Captura de demonstração: $titulo',
                    errorBuilder: (_, __, ___) => const Center(
                        child: Text('Prévia indisponível',
                            style: TextStyle(color: _muted))))),
          )),
          const SizedBox(height: 22),
          _texto(titulo, tamanho: 19, peso: FontWeight.w700),
          const SizedBox(height: 6),
          _texto(descricao, tamanho: 13, cor: _muted),
          const SizedBox(height: 12),
          const Text('Demonstração — dados de exemplo',
              style: TextStyle(fontSize: 10, color: _verde)),
          TextButton.icon(onPressed: () => _ampliarCaptura(asset, titulo),
            icon: const Icon(Icons.zoom_in, color: _verde),
            label: const Text('Ampliar tela', style: TextStyle(color: _verde))),
        ]),
      );

  Widget _demonstracao(bool largo, double largura) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _titulo(
            'POR DENTRO DO APP',
            'Seu progresso, à vista.',
            'Conheça as telas do Eu Atleta. As capturas abaixo usam uma conta de demonstração '
                'com dados de exemplo, separados das contas reais.',
            largo),
        const SizedBox(height: 28),
        Wrap(spacing: 18, runSpacing: 18, children: [
          for (final captura in [
            (
              'assets/images/demo_hub.png',
              'Veja sua evolução',
              'Peso, desempenho e frequência de treinos em uma visão da sua rotina.'
            ),
            (
              'assets/images/demo_treinos.png',
              'Treine com organização',
              'Sua ficha, seus exercícios e as informações de cada série.'
            ),
            (
              'assets/images/demo_historico.png',
              'Revisite cada treino',
              'Cargas realizadas, observações e as fotos que você escolheu guardar.'
            ),
          ])
            SizedBox(
                width: largo ? (largura - 36) / 3 : largura,
                child: _captura(captura.$1, captura.$2, captura.$3)),
        ]),
      ]);

  Widget _gratuito(bool largo) => Container(
        key: _apoioKey,
        padding: EdgeInsets.all(largo ? 40 : 24),
        decoration: BoxDecoration(
            color: const Color(0xFF102B1D),
            border: Border.all(color: const Color(0xFF28543B)),
            borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _etiqueta('GRÁTIS PARA USAR. LIVRE PARA APOIAR.'),
          const SizedBox(height: 20),
          _texto('Seu próximo treino não precisa de uma assinatura.',
              tamanho: largo ? 34 : 26, peso: FontWeight.w800, altura: 1.2),
          const SizedBox(height: 16),
          _texto(
              'O app e o site são gratuitos. O projeto recebe doações voluntárias '
              'de quem quer ajudar a manter o Eu Atleta em movimento. '
              'Contribuir é uma escolha, não uma condição para usar.',
              tamanho: 15,
              cor: _muted),
          const SizedBox(height: 24),
          _botaoCriar(),
          const Divider(height: 48, color: Color(0xFF28543B)),
          _texto('Apoie o Eu Atleta', tamanho: 19, peso: FontWeight.w700),
          const SizedBox(height: 10),
          if (widget.pixCopiaCola?.trim().isNotEmpty == true) ...[
            if (widget.pixQr != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: widget.pixQr!),
            _texto('Pix copia e cola', tamanho: 13, cor: _muted),
            const SizedBox(height: 8),
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _fundo, borderRadius: BorderRadius.circular(10)),
                child: SelectableText(widget.pixCopiaCola!.trim(),
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 12))),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: _copiarPix,
                style: OutlinedButton.styleFrom(
                    foregroundColor: _verde,
                    side: const BorderSide(color: Color(0xFF427957))),
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copiar código Pix')),
          ] else ...[
            // TODO: configurar DONATION_PIX_CODE com o Pix real antes de exibir QR.
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.qr_code_2_rounded, color: _verde, size: 32),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _texto('QR Code disponível em breve',
                        tamanho: 14, peso: FontWeight.w700),
                    _texto('Estamos preparando a opção de apoio por Pix.',
                        tamanho: 13, cor: _muted),
                  ])),
            ]),
          ],
        ]),
      );

  Widget _faq(bool largo) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _titulo('DÚVIDAS FREQUENTES', 'Antes de começar.',
            'O essencial para conhecer o Eu Atleta.', largo),
        const SizedBox(height: 24),
        for (final pergunta in const [
          (
            'Preciso pagar para usar?',
            'Não. O app e o site são gratuitos. As doações são voluntárias.'
          ),
          (
            'Posso usar sem personal?',
            'Sim. Você pode organizar sua própria ficha e acompanhar seus registros. Se já tem personal no app, sua conta pode ser vinculada a ele.'
          ),
          (
            'O treino funciona sem internet?',
            'Você pode registrar seus treinos no aparelho offline. A sincronização precisa de conexão; vídeos do YouTube e Google Drive também precisam de internet para reproduzir.'
          ),
          (
            'E os serviços de personal?',
            'O uso do app é gratuito. A contratação de serviços de profissionais é independente e pode ter valores combinados com cada profissional.'
          ),
          (
            'Esses gráficos já aparecem na minha conta?',
            'Os gráficos usam os registros da sua conta. As imagens desta página são demonstrações com dados de exemplo e não preenchem seu cadastro.'
          ),
        ])
          Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: _painel,
                  border: Border.all(color: _linha),
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                  iconColor: _verde,
                  collapsedIconColor: _muted,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title:
                      _texto(pergunta.$1, tamanho: 15, peso: FontWeight.w600),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: _texto(pergunta.$2, cor: _muted, tamanho: 14))
                  ])),
      ]);

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: _fundo,
        child: SafeArea(
            bottom: false,
            child: LayoutBuilder(builder: (context, box) {
              final largo = box.maxWidth >= 1000;
              final margem = box.maxWidth >= 700 ? 40.0 : 20.0;
              return SingleChildScrollView(
                  child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: margem),
                      child: LayoutBuilder(builder: (context, conteudo) {
                        final largura = conteudo.maxWidth;
                        final espaco = largo ? 88.0 : 56.0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _cabecalho(largo),
                            const Divider(height: 1, color: _linha),
                            SizedBox(height: largo ? 64 : 40),
                            if (largo)
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(flex: 6, child: _heroTexto(true)),
                                    const SizedBox(width: 56),
                                    Expanded(
                                        flex: 5,
                                        child: Align(
                                            alignment: Alignment.centerRight,
                                            child: _login())),
                                  ])
                            else ...[
                              _heroTexto(false),
                              const SizedBox(height: 36),
                              Align(
                                  alignment: Alignment.center, child: _login()),
                            ],
                            SizedBox(height: espaco),
                            _recursos(largo, largura),
                            SizedBox(height: espaco),
                            _demonstracao(largo, largura),
                            SizedBox(height: espaco),
                            _gratuito(largo),
                            SizedBox(height: espaco),
                            _faq(largo),
                            const SizedBox(height: 56),
                            const Divider(height: 1, color: _linha),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 28),
                                child: Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    spacing: 24,
                                    runSpacing: 12,
                                    children: [
                                      _texto('EU ATLETA',
                                          tamanho: 15, peso: FontWeight.w800),
                                      _texto(
                                          'App e site gratuitos • Apoio voluntário',
                                          tamanho: 12,
                                          cor: _muted),
                                      const VersaoAppLabel(cor: _muted),
                                      TextButton(
                                          onPressed: () => _irPara(_loginKey),
                                          child: const Text(
                                              'Entrar na minha conta',
                                              style: TextStyle(color: _verde))),
                                    ])),
                          ],
                        );
                      })),
                ),
              ));
            })),
      );
}
