// Classe Endereco
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/data/models/empresa_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/regime_tributario_model.dart';
import 'package:task_manager_flutter/data/models/file_attachment_model.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';

class Endereco {
  int? id;
  String? rua;
  String? numero;
  String? bairro;
  Cidade? cidade;
  Estado? estado;
  Pais? pais;
  String? cep;
  int? parceiroId;

  Endereco({
    this.id,
    this.rua,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
    this.parceiroId,
  });

  // Método para deserializar o JSON em um objeto Endereco
  Endereco.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    rua = json['rua'];
    numero = json['numero'];
    bairro = json['bairro'];
    pais = json['pais'] != null ? Pais.fromJson(json['pais']) : null;
    cidade = json['cidade'] != null ? Cidade.fromJson(json['cidade']) : null;
    estado = json['estado'] != null ? Estado.fromJson(json['estado']) : null;
    cep = json['cep'];
    parceiroId = json['parceiroId'];
  }

  // Método para serializar o objeto Endereco em JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['rua'] = rua;
    data['numero'] = numero;
    data['bairro'] = bairro;
    data['cidade'] = cidade;
    data['estado'] = estado;
    data['cep'] = cep;
    data['parceiroId'] = parceiroId;
    return data;
  }
}

class ParceiroModel {
  String? status;
  String? token;
  List<Parceiro>? parceiros;

  ParceiroModel({this.status, this.token, this.parceiros});

  ParceiroModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    parceiros = json['data'] != null
        ? Parceiro.fromJsonList(json['data']['account'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (parceiros != null) {
      data['data'] = parceiros!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}

// Classe Parceiro
class Parceiro {
  int? id;
  String? nome;
  String? cpf;
  String? codProdutor;
  String? email;
  String? telefone1;
  String? telefone2;
  String? razaoSocial;
  int? codPersonal;
  String? incrMun;
  String? status;
  Endereco? endereco;
  Empresa? empresa;
  Parceiro? parceiro; // autorreferência
  RegimeTributario? regime;
  FileAttachment? fileAttachment; // novo campo do backend
  double? valorMensal;
  String? observacao;
  String? tipoCliente; // novo campo
  String? ie; // novo campo

  Parceiro({
    this.id,
    this.nome,
    this.cpf,
    this.codProdutor,
    this.email,
    this.telefone1,
    this.telefone2,
    this.razaoSocial,
    this.codPersonal,
    this.incrMun,
    this.status,
    this.endereco,
    this.empresa,
    this.parceiro,
    this.regime,
    this.fileAttachment,
    this.valorMensal,
    this.observacao,
    this.tipoCliente,
    this.ie,
  });

  // Deserialização (fromJson)
  Parceiro.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    cpf = json['cpf'];
    codProdutor = json['codProdutor'];
    email = json['email'];
    telefone1 = json['telefone1'];
    telefone2 = json['telefone2'];
    razaoSocial = json['razaoSocial'];
    codPersonal = json['codPersonal'];
    incrMun = json['incrMun'];
    status = json['status'];

    endereco =
        json['endereco'] != null ? Endereco.fromJson(json['endereco']) : null;
    empresa =
        json['empresa'] != null ? Empresa.fromJson(json['empresa']) : null;
    parceiro =
        json['parceiro'] != null ? Parceiro.fromJson(json['parceiro']) : null;
    regime = json['regime'] != null
        ? RegimeTributario.fromJson(json['regime'])
        : null;
    fileAttachment = json['fileAttachment'] != null
        ? FileAttachment.fromJson(json['fileAttachment'])
        : null;

    valorMensal = json['valorMensal'] != null
        ? double.tryParse(json['valorMensal'].toString())
        : null;
    observacao = json['observacao'];
    tipoCliente = json['tipoCliente'];
    ie = json['ie'];
  }

  // Serialização (toJson)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    data['cpf'] = cpf;
    data['codProdutor'] = codProdutor;
    data['email'] = email;
    data['telefone1'] = telefone1;
    data['telefone2'] = telefone2;
    data['razaoSocial'] = razaoSocial;
    data['codPersonal'] = codPersonal;
    data['incrMun'] = incrMun;
    data['status'] = status;

    if (endereco != null) data['endereco'] = endereco!.toJson();
    if (empresa != null) data['empresa'] = empresa!.toJson();
    if (parceiro != null) data['parceiro'] = parceiro!.toJson();
    if (regime != null) data['regime'] = regime!.toJson();
    if (fileAttachment != null) {
      data['fileAttachment'] = fileAttachment!.toJson();
    }

    data['valorMensal'] = valorMensal;
    data['observacao'] = observacao;
    data['tipoCliente'] = tipoCliente;
    data['ie'] = ie;
    return data;
  }

  static List<Parceiro> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Parceiro.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> loadCategorias() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allRegimetributario,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'].toString(), 'label': item['codigo']},
          )
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> _loadEmpresas() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allEmpresas,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'].toString(), 'label': item['nome']},
          )
          .toList();
    }
    return [];
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.person,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
      fieldType: FieldType.text,
    ),
    const FieldConfig(
        label: "CPF",
        fieldName: "cpf",
        icon: Icons.badge,
        isInForm: true,
        isFilterable: true,
        isVisibleByDefault: true,
        isFixed: true,
        fieldType: FieldType.cnpj),
    const FieldConfig(
        label: "Email",
        fieldName: "email",
        icon: Icons.email,
        isInForm: true,
        isVisibleByDefault: true,
        isFixed: true,
        fieldType: FieldType.email),
    const FieldConfig(
        label: "Telefone",
        fieldName: "telefone1",
        icon: Icons.phone,
        isInForm: true,
        isVisibleByDefault: true,
        isFixed: true,
        fieldType: FieldType.phone),
    const FieldConfig(
        label: "Razão Social",
        fieldName: "razaoSocial",
        icon: Icons.apartment,
        isInForm: true,
        isVisibleByDefault: false,
        isFixed: false,
        fieldType: FieldType.text),
    const FieldConfig(
        label: "Inscrição Municipal",
        fieldName: "incrMun",
        icon: Icons.assignment,
        isInForm: true,
        isVisibleByDefault: false,
        isFixed: false,
        fieldType: FieldType.number),
    const FieldConfig(
      label: "Valor Mensal",
      fieldName: "valorMensal",
      icon: Icons.attach_money,
      isInForm: true,
      fieldType: FieldType.number,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Observação",
      fieldName: "observacao",
      icon: Icons.notes,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    FieldConfig(
      label: "Regime",
      fieldName: "regime",
      displayFieldName: "regime.codigo", // Campo aninhado para exibição
      icon: Icons.business_center,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return await loadCategorias();
      },
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
    ),
    FieldConfig(
        label: "Empresa",
        fieldName: "empresa",
        displayFieldName: "empresa.nome",
        icon: Icons.business,
        isInForm: true,
        isFilterable: true,
        fieldType: FieldType.dropdown,
        dropdownFutureBuilder: () async {
          return await _loadEmpresas();
        },
        dropdownValueField: 'value',
        dropdownDisplayField: 'label',
        isRequired: false,
        isVisibleByDefault: true,
        enabled: true,
        dropdownSelectedValue: pegarEmpresaLogada()),
  ];
}

class PaisModel {
  String? status;
  String? token;
  List<Pais>? pais;

  PaisModel({this.status, this.token, this.pais});

  PaisModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    pais =
        json['data'] != null ? Pais.fromJsonList(json['data']['account']) : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (pais != null) {
      data['data'] = pais!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}

class EstadoModel {
  String? status;
  String? token;
  List<Estado>? estados;

  EstadoModel({this.status, this.token, this.estados});

  EstadoModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    estados = json['data'] != null
        ? Estado.fromJsonList(json['data']['account'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (estados != null) {
      data['data'] = estados!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}

class CidadeModel {
  String? status;
  String? token;
  List<Cidade>? estados;

  CidadeModel({this.status, this.token, this.estados});

  CidadeModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    estados = json['data'] != null
        ? Cidade.fromJsonList(json['data']['account'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (estados != null) {
      data['data'] = estados!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}

// Model classes
class Pais {
  final int id;
  final String nome;
  final String nomePt;
  final String iso2;
  final String iso3;
  final int bacen;

  Pais({
    required this.id,
    required this.nome,
    required this.nomePt,
    required this.iso2,
    required this.iso3,
    required this.bacen,
  });

  factory Pais.fromJson(Map<String, dynamic> json) {
    return Pais(
      id: json['id'],
      nome: utf8.decode(latin1.encode(json['nome'])),
      nomePt: json['nomePt'],
      iso2: json['iso2'],
      iso3: json['iso3'] ?? '',
      bacen: json['bacen'],
    );
  }

  // Método para serializar o objeto Parceiro em JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    data['nomePt'] = nomePt;
    data['iso2'] = iso2;
    data['iso3'] = iso3;
    data['bacen'] = bacen;
    return data;
  }

  static List<Pais> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Pais.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class Estado {
  final int id;
  final String nome;
  final String uf;
  final int ibge;
  final Pais pais;

  Estado({
    required this.id,
    required this.nome,
    required this.uf,
    required this.ibge,
    required this.pais,
  });

  factory Estado.fromJson(Map<String, dynamic> json) {
    final nomeRaw = json['nome'];
    String nomeFinal;

    try {
      // converte Latin1 para UTF-8 se for string válida
      nomeFinal = (nomeRaw is String)
          ? utf8.decode(latin1.encode(nomeRaw))
          : 'Sem nome';
    } catch (_) {
      nomeFinal = nomeRaw?.toString() ?? 'Sem nome';
    }

    return Estado(
      id: json['id'],
      nome: nomeFinal,
      uf: json['uf'],
      ibge: json['ibge'],
      pais: (json['pais'] != null && json['pais'] is Map<String, dynamic>)
          ? Pais.fromJson(json['pais'] as Map<String, dynamic>)
          : Pais(
              id: 0,
              nome: 'Brasil',
              nomePt: 'Brasil',
              iso2: 'BR',
              iso3: 'BRA',
              bacen: 1058,
            ),
    );
  }

  // Método para serializar o objeto Parceiro em JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    data['uf'] = uf;
    data['ibge'] = ibge;
    data['pais'] = pais;
    return data;
  }

  static List<Estado> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Estado.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class Cidade {
  final int id;
  final String nome;
  // final int uf;
  final int ibge;
  final String latLon;

  Cidade({
    required this.id,
    required this.nome,
    //  required this.uf,
    required this.ibge,
    required this.latLon,
  });

  factory Cidade.fromJson(Map<String, dynamic> json) {
    return Cidade(
      id: json['id'],
      nome: json['nome']?.toString() ?? '',
      //   uf: json['uf'],
      ibge: json['ibge'],
      latLon: json['latLon'] ?? '',
    );
  }

  // Método para serializar o objeto Parceiro em JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    // data['uf'] = uf;
    data['ibge'] = ibge;
    data['latLon'] = latLon;
    return data;
  }

  static List<Cidade> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Cidade.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
