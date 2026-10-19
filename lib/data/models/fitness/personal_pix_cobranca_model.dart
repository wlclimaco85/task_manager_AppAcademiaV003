import 'dart:convert';

/// Tipos de chave Pix
class TipoChavePix {
  static const String telefone = 'Telefone';
  static const String email = 'E-mail';
  static const String cpfCnpj = 'CPF/CNPJ';
  static const String aleatoria = 'Chave Aleatória';

  static const List<String> todos = [
    telefone,
    email,
    cpfCnpj,
    aleatoria,
  ];
}

/// Modelo para configuração de Cobrança Pix e Valor da Mensalidade do Personal Trainer
class PersonalPixCobrancaModel {
  final String chavePix;
  final String tipoChavePix;
  final String nomeTitular;
  final String cidade;
  final double valorMensalidadePadrao;
  final String pixCopiaECola;

  PersonalPixCobrancaModel({
    this.chavePix = '',
    this.tipoChavePix = TipoChavePix.cpfCnpj,
    this.nomeTitular = '',
    this.cidade = 'SAO PAULO',
    this.valorMensalidadePadrao = 200.0,
    this.pixCopiaECola = '',
  });

  bool get configurado =>
      chavePix.trim().isNotEmpty || pixCopiaECola.trim().isNotEmpty;

  PersonalPixCobrancaModel copyWith({
    String? chavePix,
    String? tipoChavePix,
    String? nomeTitular,
    String? cidade,
    double? valorMensalidadePadrao,
    String? pixCopiaECola,
  }) {
    return PersonalPixCobrancaModel(
      chavePix: chavePix ?? this.chavePix,
      tipoChavePix: tipoChavePix ?? this.tipoChavePix,
      nomeTitular: nomeTitular ?? this.nomeTitular,
      cidade: cidade ?? this.cidade,
      valorMensalidadePadrao:
          valorMensalidadePadrao ?? this.valorMensalidadePadrao,
      pixCopiaECola: pixCopiaECola ?? this.pixCopiaECola,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chavePix': chavePix,
      'tipoChavePix': tipoChavePix,
      'nomeTitular': nomeTitular,
      'cidade': cidade,
      'valorMensalidadePadrao': valorMensalidadePadrao,
      'pixCopiaECola': pixCopiaECola,
    };
  }

  factory PersonalPixCobrancaModel.fromMap(Map<String, dynamic> map) {
    return PersonalPixCobrancaModel(
      chavePix: map['chavePix']?.toString() ?? '',
      tipoChavePix: map['tipoChavePix']?.toString() ?? TipoChavePix.cpfCnpj,
      nomeTitular: map['nomeTitular']?.toString() ?? '',
      cidade: map['cidade']?.toString() ?? 'SAO PAULO',
      valorMensalidadePadrao: (map['valorMensalidadePadrao'] is num)
          ? (map['valorMensalidadePadrao'] as num).toDouble()
          : double.tryParse(map['valorMensalidadePadrao']?.toString() ?? '200') ??
              200.0,
      pixCopiaECola: map['pixCopiaECola']?.toString() ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PersonalPixCobrancaModel.fromJson(String source) =>
      PersonalPixCobrancaModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  /// Obtém o código Pix Copia e Cola pronto para uso (utiliza o colado ou gera o padrão BACEN)
  String obterCodigoPixParaValor({double? valor}) {
    final v = valor ?? valorMensalidadePadrao;
    if (pixCopiaECola.trim().isNotEmpty && (valor == null || valor == valorMensalidadePadrao)) {
      return pixCopiaECola.trim();
    }
    if (chavePix.trim().isNotEmpty) {
      return gerarPayloadPixBacen(
        chave: chavePix.trim(),
        nome: nomeTitular.trim().isNotEmpty ? nomeTitular.trim() : 'PERSONAL TRAINER',
        cidade: cidade.trim().isNotEmpty ? cidade.trim() : 'SAO PAULO',
        valor: v > 0 ? v : null,
      );
    }
    return pixCopiaECola.trim();
  }

  /// Gera a string do Pix Copia e Cola no padrão EMV QRCPS (BACEN / BR Code)
  static String gerarPayloadPixBacen({
    required String chave,
    required String nome,
    required String cidade,
    double? valor,
    String txId = '***',
  }) {
    String formatTLV(String id, String value) {
      final len = value.length.toString().padLeft(2, '0');
      return '$id$len$value';
    }

    String removerAcentos(String str) {
      const comAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÌÍÎÏìíîïÙÚÛÜùúûüÑñÇç';
      const semAcento = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeIIIIiiiiUUUUuuuuNnCc';
      var res = str;
      for (var i = 0; i < comAcento.length; i++) {
        res = res.replaceAll(comAcento[i], semAcento[i]);
      }
      return res.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
    }

    // 00: Payload Format Indicator
    final pfi = formatTLV('00', '01');

    // 26: Merchant Account Information (Pix)
    final gui = formatTLV('00', 'BR.GOV.BCB.PIX');
    final key = formatTLV('01', chave.trim());
    final mai = formatTLV('26', '$gui$key');

    // 52: Merchant Category Code (0000 = não especificado)
    final mcc = formatTLV('52', '0000');

    // 53: Transaction Currency (986 = BRL)
    final curr = formatTLV('53', '986');

    // 54: Transaction Amount (opcional)
    final amount = valor != null && valor > 0
        ? formatTLV('54', valor.toStringAsFixed(2))
        : '';

    // 58: Country Code (BR)
    final country = formatTLV('58', 'BR');

    // 59: Merchant Name (máx 25)
    var nomeLimpo = removerAcentos(nome.toUpperCase().trim());
    if (nomeLimpo.isEmpty) nomeLimpo = 'PERSONAL';
    if (nomeLimpo.length > 25) nomeLimpo = nomeLimpo.substring(0, 25);
    final merName = formatTLV('59', nomeLimpo);

    // 60: Merchant City (máx 15)
    var cidadeLimpa = removerAcentos(cidade.toUpperCase().trim());
    if (cidadeLimpa.isEmpty) cidadeLimpa = 'BRASIL';
    if (cidadeLimpa.length > 15) cidadeLimpa = cidadeLimpa.substring(0, 15);
    final merCity = formatTLV('60', cidadeLimpa);

    // 62: Additional Data Field Template (txid)
    final tx = formatTLV('05', txId);
    final addData = formatTLV('62', tx);

    // Concatena tudo antes do CRC
    final payloadSemCrc = '$pfi$mai$mcc$curr$amount$country$merName$merCity$addData' '6304';

    // Calcula CRC16-CCITT (0xFFFF, polinomio 0x1021)
    final crc = calcularCrc16(payloadSemCrc);

    return '$payloadSemCrc$crc';
  }

  /// Calcula o CRC16-CCITT no padrão BACEN
  static String calcularCrc16(String input) {
    var crc = 0xFFFF;
    final bytes = utf8.encode(input);
    for (final byte in bytes) {
      crc ^= byte << 8;
      for (var i = 0; i < 8; i++) {
        crc = ((crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1) & 0xFFFF;
      }
    }
    return crc.toRadixString(16).padLeft(4, '0').toUpperCase();
  }
}
