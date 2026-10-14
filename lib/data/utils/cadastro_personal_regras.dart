/// Regras do wizard de cadastro do personal (sem dependência de UI).
library;

/// Dias da semana: abreviação exibida nos chips e nome enviado à API.
const diasSemanaAbrev = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const diasSemanaApi = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

/// Presets de planos sugeridos ao personal (nome, aulas por mês).
const presetsPlano = [
  ('Mensal 2x/semana', 8),
  ('Mensal 3x/semana', 12),
  ('Mensal 5x/semana', 20),
  ('Pacote 10 aulas', 10),
];

/// UFs aceitas no CREF.
const ufs = [
  'AC',
  'AL',
  'AM',
  'AP',
  'BA',
  'CE',
  'DF',
  'ES',
  'GO',
  'MA',
  'MG',
  'MS',
  'MT',
  'PA',
  'PB',
  'PE',
  'PI',
  'PR',
  'RJ',
  'RN',
  'RO',
  'RR',
  'RS',
  'SC',
  'SE',
  'SP',
  'TO',
];

String somenteDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

/// CREF no formato oficial 000000-G/UF (G = graduado, P = provisionado).
String montarCref(String numero, String categoria, String uf) =>
    '${somenteDigitos(numero).padLeft(6, '0')}-$categoria/$uf';

String? validarCref(String numero, String categoria, String? uf) {
  final digitos = somenteDigitos(numero);
  if (digitos.isEmpty) return 'Informe o número do CREF';
  if (digitos.length > 6) return 'Formato inválido. Use 000000-G/UF.';
  if (categoria != 'G' && categoria != 'P') return 'Escolha G (graduado) ou P (provisionado)';
  if (uf == null || !ufs.contains(uf)) return 'Escolha a UF do CREF';
  return null;
}

/// Máscara do celular brasileiro: (DD) 9XXXX-XXXX.
String mascararCelular(String texto) {
  final d = somenteDigitos(texto);
  final s = d.length > 11 ? d.substring(0, 11) : d;
  if (s.length <= 2) return s.isEmpty ? '' : '($s';
  if (s.length <= 7) return '(${s.substring(0, 2)}) ${s.substring(2)}';
  return '(${s.substring(0, 2)}) ${s.substring(2, 7)}-${s.substring(7)}';
}

String? validarWhatsapp(String texto) {
  final d = somenteDigitos(texto);
  if (d.isEmpty) return 'Informe o WhatsApp';
  if (d.length != 11 || d[2] != '9') return 'Informe um celular com DDD (11 dígitos)';
  return null;
}

/// WhatsApp com DDI para a API e para o link wa.me (55 + DDD + número).
String whatsappComDdi(String texto) => '55${somenteDigitos(texto)}';

/// Lê "R$ 1.234,56" (ou "1234,56") como 1234.56.
double? lerMoeda(String texto) {
  final d = somenteDigitos(texto);
  if (d.isEmpty) return null;
  return int.parse(d) / 100;
}

/// Máscara de moeda digitada pelos centavos: "12345" -> "R$ 123,45".
String mascararMoeda(String texto) {
  final valor = lerMoeda(texto);
  return valor == null ? '' : formatarMoeda(valor);
}

String formatarMoeda(double valor) {
  final partes = valor.toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return 'R\$ $inteiro,${partes[1]}';
}

/// Valor de cada aula dentro do plano (valor ÷ aulas).
double? valorPorAula(double? valor, int? aulas) =>
    (valor == null || aulas == null || aulas <= 0) ? null : valor / aulas;

/// Faixa de atendimento: local (academia ou independente), dias e horário.
class FaixaAtendimento {
  FaixaAtendimento({
    required this.academiaId,
    required this.localNome,
    required Set<int> dias,
    required this.inicio,
    required this.fim,
  }) : dias = Set.of(dias);

  /// null = atendimento sem academia (independente/domicílio/online).
  final int? academiaId;
  final String localNome;
  final Set<int> dias; // 0 = segunda ... 6 = domingo
  final String inicio; // HH:mm
  final String fim; // HH:mm

  Map<String, dynamic> toApi() => {
        'academiaId': academiaId,
        'dias': [for (final d in (dias.toList()..sort())) diasSemanaApi[d]],
        'inicio': inicio,
        'fim': fim,
      };

  String get resumo => '${resumoDias(dias)} · $inicio–$fim';

  /// Formato salvo no rascunho local do wizard.
  Map<String, dynamic> toRascunho() => {
        'academiaId': academiaId,
        'localNome': localNome,
        'dias': dias.toList()..sort(),
        'inicio': inicio,
        'fim': fim,
      };

  factory FaixaAtendimento.fromRascunho(Map<String, dynamic> m) => FaixaAtendimento(
        academiaId: m['academiaId'] as int?,
        localNome: m['localNome']?.toString() ?? '',
        dias: {for (final d in (m['dias'] as List? ?? const [])) d as int},
        inicio: m['inicio']?.toString() ?? '06:00',
        fim: m['fim']?.toString() ?? '10:00',
      );
}

/// Chave do rascunho local do wizard (a senha nunca é salva).
const chaveRascunhoPersonal = 'rascunho_cadastro_personal_v1';

/// Campos que nunca podem ir para o rascunho local.
const camposProibidosRascunho = {'senha', 'confirmarSenha'};

/// Remove dados sensíveis antes de salvar o rascunho no aparelho.
Map<String, dynamic> limparRascunho(Map<String, dynamic> dados) => {
      for (final e in dados.entries)
        if (!camposProibidosRascunho.contains(e.key)) e.key: e.value
    };

int _minutos(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String formatarHora(int hora, int minuto) =>
    '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

/// "Seg–Sex", "Seg, Qua, Sex", "Seg–Qua, Sáb".
String resumoDias(Set<int> dias) {
  final ordenados = dias.toList()..sort();
  final grupos = <List<int>>[];
  for (final d in ordenados) {
    if (grupos.isNotEmpty && grupos.last.last == d - 1) {
      grupos.last.add(d);
    } else {
      grupos.add([d]);
    }
  }
  return grupos
      .expand((g) => g.length >= 3
          ? ['${diasSemanaAbrev[g.first]}–${diasSemanaAbrev[g.last]}']
          : g.map((d) => diasSemanaAbrev[d]))
      .join(', ');
}

/// Erro da faixa isolada (sem dias ou horário invertido).
String? validarFaixa(Set<int> dias, String inicio, String fim) {
  if (dias.isEmpty) return 'Escolha pelo menos um dia';
  if (_minutos(fim) <= _minutos(inicio)) return 'O horário "Até" precisa ser depois de "Das"';
  return null;
}

/// Primeiro conflito da [nova] faixa com as [existentes] (mesmo dia e horários
/// sobrepostos), em texto para o usuário; null se não houver.
String? conflitoFaixa(FaixaAtendimento nova, List<FaixaAtendimento> existentes) {
  for (final f in existentes) {
    for (final dia in nova.dias.intersection(f.dias).toList()..sort()) {
      final sobrepoe = _minutos(nova.inicio) < _minutos(f.fim) && _minutos(f.inicio) < _minutos(nova.fim);
      if (sobrepoe) {
        return 'Conflito: ${diasSemanaAbrev[dia]} ${f.inicio}–${f.fim} já está em ${f.localNome}';
      }
    }
  }
  return null;
}
