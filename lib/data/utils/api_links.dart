class ApiLinks {
  ApiLinks._();
  static const String _baseIp = "http://192.168.56.1:8088";
   // "https://appacademia-production-be7e.up.railway.app";
  //static const String _chatId = 'ws://192.168.114.1:8088/boletobancos';

  static const String _chatId = 'ws://192.168.114.1:8088/boletobancos';
 // "wss://appacademia-production-be7e.up.railway.app/boletobancos";
  //"http://192.168.100.41:8088";
  //  "http://192.168.114.1:8088";
  // "http://192.168.100.113:8088";
  //  "http://192.168.146.1:8088";
  // // "http://192.168.100.41:8088";
  // "http://192.168.100.41:8088"; // "http://192.168.12.19:8088"; //
  //'https://academia-app-919f42758cd6.herokuapp.com'; // "http://192.168.12.28:8088";
  // "http://192.168.12.23:8088"; // "http://192.168.56.1:8088"; // ; // //"http://192.168.12.23:8088";
  //static const String _baseIp = "http://192.168.56.1:8088"; //"http://192.168.12.23:8088";
  static const String _baseUrl = 'https://task.teamrabbil.com/api/v1';
  static const String _baseUrlNew = '$_baseIp/boletobancos';
  //static const String _baseUrlNew =
  //    'https://academia-app-919f42758cd6.herokuapp.com/boletobancos';
  static const String allPersonal = '$_baseUrlNew/personal/findAll';
  static const String allAcademia = '$_baseUrlNew/academia/findAll';
  static const String allModalidade = '$_baseUrlNew/modalidade/findAll';
  static const String allTipoRefeicao = '$_baseUrlNew/dieta/findByRefeicao';
  static const String allUniMeds = '$_baseUrlNew/unidade/findAll';
  static const String insertPersonal = '$_baseUrlNew/personal/inserir';
  static const String insertSuplemento = '$_baseUrlNew/suplemento/insert';
  static const String insertAcademia = '$_baseUrlNew/academia/inserir';
  static const String allSuplementoAluno =
      '$_baseUrlNew/suplemento/findByIdAluno';
  static const String insertAluno = '$_baseUrlNew/rest/auth/inserirAluno';
  static String regestration = '$_baseUrl/registration';
  static String profileUpdate = '$_baseUrl/profileUpdate';
  static const String insertExame = '$_baseUrlNew/exame/inserir';
  static const String findByIdAluno = '$_baseUrlNew/exame/findByParceiros';
  static const String insertMedicamento = '$_baseUrlNew/medicamento/inserir';
  static const String findByAlunoByMedicamento =
      '$_baseUrlNew/medicamento/findByParceiros';
  static const String findByAlunoByDieta = '$_baseUrlNew/dieta/findByParceiros';
  // static String login = '$_baseUrl/login';
  // static String login = '$_baseUrl/rest/auth/login';

  // static String login = 'http://192.168.56.1:8088/boletobancos/rest/auth/login';
  static String login = '$_baseUrlNew/rest/auth/login';
  static String recoverVerifyEmail(String email) =>
      '$_baseUrl/RecoverVerifyEmail/$email';
  static String recoverVerifyOTP(String email, String otp) =>
      '$_baseUrl/RecoverVerifyOTP/$email/$otp';
  static String recoverResetPassword = '$_baseUrl/RecoverResetPass';

  static String createTask = '$_baseUrl/createTask';
  static String newTaskStatus = '$_baseUrl/listTaskByStatus/New';

  static String completedTaskStatus = '$_baseUrl/listTaskByStatus/Completed';
  static String inProgressTaskStatus = '$_baseUrl/listTaskByStatus/Progress';
  static String cancelledTaskStatus = '$_baseUrl/listTaskByStatus/Canceled';
  static String updateTask(String id, String status) =>
      '$_baseUrl/updateTaskStatus/$id/$status';
  static String taskStatusCount = '$_baseUrl/listTaskByStatus/taskStatusCount';
  static String deleteTask(String taskId) => '$_baseUrl/deleteTask/$taskId';
  static String allNoticias = '$_baseUrlNew/api/noticias';
  static String allCotacoes = '$_baseUrlNew/api/cotacoes';
  static String allVendas = '$_baseUrlNew/api/produtos';
  static String insertNegociacao = '$_baseUrlNew/api/negociacao';
  static String allClassificacao = '$_baseUrlNew/api/classificacoes';
  static String parceiroById = '$_baseUrlNew/api/parceiro/parceiro';
  static String insertProduto = '$_baseUrlNew/api/produtos';
  static String fecthItensAVenda = '$_baseUrlNew/api/produtos/vendedor/';
  static String fecthItensACompra = '$_baseUrlNew/api/produtos/comprador/';
  static String fecthItensANegociar = '$_baseUrlNew/api/produtos/negociacoes/';
  static String insertCotacaoFrete = '$_baseUrlNew/api/cotacaofrete';
  static String allAlerts = '$_baseUrlNew/api/alert';
  static String alertFindByUser = '$_baseUrlNew/api/alert/byUser/';
  static String compradorFindByUser = '$_baseUrlNew/api/produtos/comprador/';
  static String vendedorFindByUser = '$_baseUrlNew/api/produtos/vendedor/';
  static String negociacaoFindByUser = '$_baseUrlNew/produtos/negociacoes/';
  static String insertParceiro = '$_baseUrlNew/api/parceiro/insert';
  static String fecthAllCotacaoDollar = '$_baseUrlNew/api/cotacoes/dollar';
  static String confirmarNegociacao = '$_baseUrlNew/api/negociacao/finalizar';
  static String confirmarRecusar = '$_baseUrlNew/api/negociacao/recusar';
  static String contraProposta = '$_baseUrlNew/api/negociacao/contraposta';
  static String downloadContrato = '$_baseUrlNew/api/contrato/download';
  static String upLoadContrato = '$_baseUrlNew/api/contrato/upload';
  static String fecthUltimoTermo = '$_baseUrlNew/api/termos';
  static String fecthProdutosById = '$_baseUrlNew/api/produtos/';
  static String fecthAllPaises = '$_baseUrlNew/api/paises';
  static String fecthEstadoByPais = '$_baseUrlNew/api/estados/by-pais/';
  static String fecthCidadeByEstado = '$_baseUrlNew/api/cidade/by-estado/';
  static String fecthCalcFrete = '$_baseUrlNew/api/rota/calcular';
  static String fecthChats = '$_baseUrlNew/api/chat/user';
  static String fecthChatById = '$_baseUrlNew/api/chat/messages?chatId=';
  static String getCategorias = '$_baseUrlNew/api/setor';

  // Comunicado
  static String allComunicados = '$_baseUrlNew/api/comunicados';
  static String createComunicado = '$_baseUrlNew/api/comunicados/insert';
  static String updateComunicado(String taskId) =>
      '$_baseUrlNew/api/comunicados/update/$taskId';
  static String deleteComunicado(String taskId) =>
      '$_baseUrlNew/api/comunicados/delete/$taskId';

  // Alimento
  static String allAlimentos = '$_baseUrlNew/api/alimentos';
  static String createAlimento = '$_baseUrlNew/api/alimentos/insert';
  static String updateAlimento(String id) =>
      '$_baseUrlNew/api/alimentos/update/$id';
  static String deleteAlimento(String id) =>
      '$_baseUrlNew/api/alimentos/delete/$id';

  // Dieta
  static String allDietas = '$_baseUrlNew/api/dietas';
  static String createDieta = '$_baseUrlNew/api/dietas/insert';
  static String updateDieta(String id) => '$_baseUrlNew/api/dietas/update/$id';
  static String deleteDieta(String id) => '$_baseUrlNew/api/dietas/delete/$id';

  // Empresa
  static String allEmpresas = '$_baseUrlNew/api/empresa';
  static String createEmpresa = '$_baseUrlNew/api/empresa/insert';
  static String updateEmpresa(String id) =>
      '$_baseUrlNew/api/empresa/update/$id';
  static String deleteEmpresa(String id) =>
      '$_baseUrlNew/api/empresa/delete/$id';

  static String empresaById(String id) => '$_baseUrlNew/api/empresa/$id';

  // Exame
  static String allExames = '$_baseUrlNew/api/exames';
  static String createExame = '$_baseUrlNew/api/exames/insert';
  static String updateExame(String id) => '$_baseUrlNew/api/exames/update/$id';
  static String deleteExame(String id) => '$_baseUrlNew/api/exames/delete/$id';

  // Exercicio
  static String allExercicios = '$_baseUrlNew/api/exercicios';
  static String createExercicio = '$_baseUrlNew/api/exercicios/insert';
  static String updateExercicio(String id) =>
      '$_baseUrlNew/api/exercicios/update/$id';
  static String deleteExercicio(String id) =>
      '$_baseUrlNew/api/exercicios/delete/$id';

  // Grupo Muscular
  static String allGruposMusculares = '$_baseUrlNew/api/grupos-musculares';
  static String createGrupoMuscular =
      '$_baseUrlNew/api/grupos-musculares/insert';
  static String updateGrupoMuscular(String id) =>
      '$_baseUrlNew/api/grupos-musculares/update/$id';
  static String deleteGrupoMuscular(String id) =>
      '$_baseUrlNew/api/grupos-musculares/delete/$id';

  // Medicamento
  static String allMedicamentos = '$_baseUrlNew/api/medicamentos';
  static String createMedicamento = '$_baseUrlNew/api/medicamentos/insert';
  static String updateMedicamento(String id) =>
      '$_baseUrlNew/api/medicamentos/update/$id';
  static String deleteMedicamento(String id) =>
      '$_baseUrlNew/api/medicamentos/delete/$id';

  // Mensalidade
  static String allMensalidades = '$_baseUrlNew/api/mensalidades';
  static String createMensalidade = '$_baseUrlNew/api/mensalidades/insert';
  static String updateMensalidade(String id) =>
      '$_baseUrlNew/api/mensalidades/update/$id';
  static String deleteMensalidade(String id) =>
      '$_baseUrlNew/api/mensalidades/delete/$id';

  // Modalidade
  static String allModalidades = '$_baseUrlNew/api/modalidades';
  static String createModalidade = '$_baseUrlNew/api/modalidades/insert';
  static String updateModalidade(String id) =>
      '$_baseUrlNew/api/modalidades/update/$id';
  static String deleteModalidade(String id) =>
      '$_baseUrlNew/api/modalidades/delete/$id';

  // Objetivo
  static String allObjetivos = '$_baseUrlNew/api/objetivos';
  static String createObjetivo = '$_baseUrlNew/api/objetivos/insert';
  static String updateObjetivo(String id) =>
      '$_baseUrlNew/api/objetivos/update/$id';
  static String deleteObjetivo(String id) =>
      '$_baseUrlNew/api/objetivos/delete/$id';

  // Parceiro
  static String allParceiros = '$_baseUrlNew/api/parceiro';
  static String createParceiro = '$_baseUrlNew/api/parceiro/insert';
  static String updateParceiro(String id) =>
      '$_baseUrlNew/api/parceiro/update/$id';
  static String deleteParceiro(String id) =>
      '$_baseUrlNew/api/parceiro/delete/$id';

  static String allParceirosPorEmp(String id) =>
      '$_baseUrlNew/api/parceiro/empresa/$id';

  // Personal
  static String allPersonais = '$_baseUrlNew/api/personais';
  static String createPersonal = '$_baseUrlNew/api/personais/insert';
  static String updatePersonal(String id) =>
      '$_baseUrlNew/api/personais/update/$id';
  static String deletePersonal(String id) =>
      '$_baseUrlNew/api/personais/delete/$id';

  // Plano
  static String allPlanos = '$_baseUrlNew/api/planos';
  static String createPlano = '$_baseUrlNew/api/planos/insert';
  static String updatePlano(String id) => '$_baseUrlNew/api/planos/update/$id';
  static String deletePlano(String id) => '$_baseUrlNew/api/planos/delete/$id';

  // Role
  static String allRoles = '$_baseUrlNew/api/role';
  static String createRole = '$_baseUrlNew/api/role';
  static String updateRole(String id) => '$_baseUrlNew/api/role/$id';
  static String deleteRole(String id) => '$_baseUrlNew/api/roles/delete/$id';

  // Setor
  static String allSetores = '$_baseUrlNew/api/setor';
  static String createSetor = '$_baseUrlNew/api/setor';
  static String updateSetor(String id) => '$_baseUrlNew/api/setor/update/$id';
  static String deleteSetor(String id) => '$_baseUrlNew/api/setor/delete/$id';

  // Suplemento
  static String allSuplementos = '$_baseUrlNew/api/suplementos';
  static String createSuplemento = '$_baseUrlNew/api/suplementos/insert';
  static String updateSuplemento(String id) =>
      '$_baseUrlNew/api/suplementos/update/$id';
  static String deleteSuplemento(String id) =>
      '$_baseUrlNew/api/suplementos/delete/$id';

  // Suplemento
  static String allAplicativos = '$_baseUrlNew/api/aplicativos';
  static String createAplicativo = '$_baseUrlNew/api/aplicativos';
  static String updateAplicativo(String id) =>
      '$_baseUrlNew/api/aplicativos/update/$id';
  static String deleteAplicativo(String id) =>
      '$_baseUrlNew/api/aplicativos/delete/$id';

  // Regime
  static String allRegimetributario = '$_baseUrlNew/api/regimetributario';
  static String createRegimetributario = '$_baseUrlNew/api/regimetributario';
  static String updateRegimetributario(String id) =>
      '$_baseUrlNew/api/regimetributario/update/$id';
  static String deleteRegimetributario(String id) =>
      '$_baseUrlNew/api/regimetributario/delete/$id';

  // Add these endpoints to your ApiLinks class
  static String get allLogins => '$_baseUrlNew/api/logins';
  static String get createLogin => '$_baseUrlNew/api/logins';
  static String updateLogin(String id) => '$_baseUrlNew/api/logins/$id';
  static String deleteLogin(String id) => '$_baseUrlNew/api/logins/$id';

  // Contas a Pagar
  static String get allContasPagar => '$_baseUrlNew/api/contas-pagar';
  static String get createContaPagar => '$_baseUrlNew/api/contas-pagar';
  static String desfazerContaPagar(String id) =>
      '$_baseUrlNew/api/contas-pagar/desfazer/$id';
  static String updateContaPagar(String id) =>
      '$_baseUrlNew/api/contas-pagar/$id';
  static String deleteContaPagar(String id) =>
      '$_baseUrlNew/api/contas-pagar/$id';
  static String registrarBaixaContaPagar(String id) =>
      '$_baseUrlNew/api/contas-pagar/$id/baixa';

  // Contas a Receber
  static String get allContasReceber => '$_baseUrlNew/api/contas-receber';
  static String get createContaReceber => '$_baseUrlNew/api/contas-receber';
  static String updateContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/$id';
  static String desfazerContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/desfazer/$id';
  static String deleteContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/$id';
  static String registrarBaixaContaReceber(String id) =>
      '$_baseUrlNew/api/contas-receber/$id/baixa';

  // Chamados
  static String get allChamados => '$_baseUrlNew/api/chamados';
  static String get createChamado => '$_baseUrlNew/api/chamados';
  static String updateChamado(String id) => '$_baseUrlNew/api/chamados/$id';
  static String deleteChamado(String id) => '$_baseUrlNew/api/chamados/$id';
  static String updateStatusChamado(String id) =>
      '$_baseUrlNew/api/chamados/$id/status';

  // Formas de Pagamento
  static String get allFormasPagamento => '$_baseUrlNew/api/forma-pagamento';
  static String get createFormaPagamento => '$_baseUrlNew/api/forma-pagamento';
  static String updateFormaPagamento(String id) =>
      '$_baseUrlNew/api/forma-pagamento/$id';
  static String deleteFormaPagamento(String id) =>
      '$_baseUrlNew/api/forma-pagamento/$id';
  static String formasPagamentoByEmpresa(String empresaId) =>
      '$_baseUrlNew/api/forma-pagamento/empresa/$empresaId';

  // Diretórios
  static String get allDiretorios => '$_baseUrlNew/api/diretorios';
  static String get createDiretorio => '$_baseUrlNew/api/diretorios';
  static String updateDiretorio(String id) => '$_baseUrlNew/api/diretorios/$id';
  static String deleteDiretorio(String id) => '$_baseUrlNew/api/diretorios/$id';

  // Arquivos
  static String get allArquivos => '$_baseUrlNew/api/arquivos';
  static String get createArquivo => '$_baseUrlNew/api/arquivos';
  static String updateArquivo(String id) => '$_baseUrlNew/api/arquivos/$id';
  static String deleteArquivo(String id) => '$_baseUrlNew/api/arquivos/$id';
  static String get uploadArquivo => '$_baseUrlNew/api/arquivos/upload';
  static String downloadArquivo(String id) =>
      '$_baseUrlNew/api/arquivos/download/$id';
  static String arquivosPorDiretorio(String diretorioId) =>
      '$_baseUrlNew/api/arquivos/diretorio/$diretorioId';

  static String get fecthAllDocumentos => '$_baseUrlNew/api/documentos';

  static String get fecthAllAlerts => '$_baseUrlNew/api/alert';

  static String get fecthAUpload => '$_baseUrlNew/api/files/upload';

  // Arquivos
  static String get allObrigacaoFiscal => '$_baseUrlNew/api/obrigacoes-fiscais';
  static String get createObrigacaoFiscal =>
      '$_baseUrlNew/api/obrigacoes-fiscais';
  static String updateObrigacaoFiscal(String id) =>
      '$_baseUrlNew/api/obrigacoes-fiscais/$id';
  static String deleteObrigacaoFiscal(String id) =>
      '$_baseUrlNew/api/obrigacoes-fiscais/$id';

  static String chatStart(String id, String setor) =>
      '$_chatId/ws-chat?user=$id&sector=$setor';

  static String chatStartfetch(String id) => '$_baseUrlNew/api/chat/$id';
  //   'ws://192.168.114.1:8088/boletobancos/ws-chat?user=${widget.userName}&sector=${widget.sector}',

  static String downloadFile(String id) =>
      '$_baseUrlNew/api/files/download/$id';

  static String get uploadFile => '$_baseUrlNew/api/files/upload';

  static String getAllTelas(String id) => '$_baseUrlNew/api/telas?nome=$id';

  // Busca tela por nome via PathVariable (retorna objeto direto com fields e actions)
  static String getTelaByNome(String nome, {int? empId, int? clienteId}) {
    final params = <String, String>{};
    if (empId != null) params['empId'] = empId.toString();
    if (clienteId != null) params['clienteId'] = clienteId.toString();
    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';
    return '$_baseUrlNew/api/telas/$nome$query';
  }

  static String getAllpreferencias(String id, String setor) =>
      ('$_baseUrlNew/api/$id/user-preferences/$setor');

  // Caso seu backend também sirva link público direto:
  static String publicFileUrl(int fileId) =>
      '$_baseUrlNew/files/public/$fileId';

  static String atualizarUsuario(int fileId) =>
      '$_baseUrlNew/api/parceiro/atualizar/$fileId';

  static String updateArquivoLido(int fileId) =>
      '$_baseUrlNew/api/parceiro/atualizar/$fileId';

  static String get getFinance => '$_baseUrlNew/api/dashboard/finance/series';
  static String get statusCounts => '$_baseUrlNew/api/dashboard/statusCounts';
  static String get chatDaily => '$_baseUrlNew/api/dashboard/chats/daily';

  static String get chatDailys => '$_baseUrlNew/api/dashboard/chats/dailys';

  static String get quarterlyComparison =>
      '$_baseUrlNew/api/dashboard/finance/quarterlyComparison';

  static String get overdue =>
      '$_baseUrlNew/api/dashboard/finance/alerts/overdue';

  static String get dueSoon =>
      '$_baseUrlNew/api/dashboard/finance/alerts/dueSoon';

  static String get kpis => '$_baseUrlNew/api/dashboard/kpis';

  static String get clientDistribution =>
      '$_baseUrlNew/api/dashboard/finance/clientDistribution';

  static String get trend => '$_baseUrlNew/api/dashboard/finance/trend';

  static String get ticketsTrend => '$_baseUrlNew/api/dashboard/tickets/trend';

  static String get financeFluxoDiario =>
      '$_baseUrlNew/api/dashboard/finance/fluxo-diario';

  static String get financeFluxoDiarioSaldo => '$_baseUrlNew/api/contas/saldos';

  static String financeFluxoEvolucao(int fileId) =>
      '$_baseUrlNew/api/contas/$fileId/evolucao/';

  static String get financeFluxoDiarioPdf =>
      '$_baseUrlNew/api/contas/extrato/pdf';

  static String get baseUrl => _baseUrlNew;

  static const String contasBancarias = '$_baseUrlNew/api/contas-bancaria';
  static const String allContasBancarias = '$contasBancarias/saldos';
  static const String createContaBancaria = contasBancarias;

  static const String buscarPaises = '$_baseUrlNew/api/pais';
  static String updateContaBancaria(String id) => '$contasBancarias/$id';
  static String deleteContaBancaria(String id) => '$contasBancarias/$id';

  static const String workflowChamados = '$_baseUrlNew/api/workflow/chamados';

  static String getAllChamados(String id) =>
      '$_baseUrlNew/api/workflow/chamados/$id/historico';

  static String registerFileOpened(String id) =>
      '$_baseUrlNew/api/workflow/chamados/$id/historico';

  static String buscarEstados(String id) =>
      '$_baseUrlNew/api/estados/by-pais/$id'; //buscarCidades

  static String buscarCidades(String id) =>
      '$_baseUrlNew/api/cidade/by-estado/$id'; //

  static String atualizarDadosPessoais(String id) =>
      '$_baseUrlNew/api/dadospessoais/$id';

  static String pontoRegistrar = "$baseUrl/api/pontos/registrar";
  static String pontoListar = "$baseUrl/api/pontos/listar";
  static String pontoPdf = "$baseUrl/api/pontos/pdf";
  static String pontoBancoHoras = "$baseUrl/api/pontos/banco-horas";

  static String contasPagarBoleto = "$baseUrl/api/boletos/importar-boleto";

  // Licenças
  static String get allLicencas => '$_baseUrlNew/api/licencas';
  static String licencaStatus(int codApp) => '$_baseUrlNew/api/licencas/status/$codApp';
  static String updateLicenca(int id) => '$_baseUrlNew/api/licencas/$id';
}
