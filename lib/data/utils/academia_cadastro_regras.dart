/// Validacoes do cadastro da academia no app. Espelham as regras do backend (FitnessAcademiaValidacao),
/// para o dono ver o erro antes de enviar.
class AcademiaCadastroRegras {
  AcademiaCadastroRegras._();

  static const List<String> ufs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR',
    'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  static final RegExp _hora = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  static String? nomeObrigatorio(String? valor) =>
      (valor == null || valor.trim().isEmpty) ? 'Informe o nome da academia' : null;

  static String soDigitos(String? texto) => (texto ?? '').replaceAll(RegExp(r'\D'), '');

  /// Vazio e permitido. Preenchido precisa ser CNPJ com digitos verificadores validos.
  static String? cnpjOpcional(String? valor) {
    final digitos = soDigitos(valor);
    if (digitos.isEmpty) return null;
    return cnpjValido(digitos) ? null : 'CNPJ invalido';
  }

  static bool cnpjValido(String d) {
    if (!RegExp(r'^\d{14}$').hasMatch(d) || d.split('').toSet().length == 1) return false;
    return _digito(d, 12, const [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) == int.parse(d[12]) &&
        _digito(d, 13, const [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) == int.parse(d[13]);
  }

  static int _digito(String d, int tamanho, List<int> pesos) {
    var soma = 0;
    for (var i = 0; i < tamanho; i++) {
      soma += int.parse(d[i]) * pesos[i];
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  static String? ufOpcional(String? valor) {
    final uf = (valor ?? '').trim().toUpperCase();
    if (uf.isEmpty) return null;
    return ufs.contains(uf) ? null : 'UF invalida';
  }

  static String? cepOpcional(String? valor) {
    final digitos = soDigitos(valor);
    if (digitos.isEmpty) return null;
    return digitos.length == 8 ? null : 'CEP deve ter 8 digitos';
  }

  static String? emailOpcional(String? valor) {
    final email = (valor ?? '').trim();
    if (email.isEmpty) return null;
    return email.contains('@') ? null : 'E-mail invalido';
  }

  /// Hora no formato HH:mm (00:00 a 23:59).
  static bool horaValida(String texto) => _hora.hasMatch(texto);

  /// Horario HH:mm com fechamento depois da abertura. Retorna null quando valido.
  static String? horario(String abertura, String fechamento) {
    if (!horaValida(abertura) || !horaValida(fechamento)) return 'Use o formato HH:mm';
    if (fechamento.compareTo(abertura) <= 0) return 'O fechamento deve ser depois da abertura';
    return null;
  }

  static String? valorPlano(String? valor) {
    final numero = double.tryParse((valor ?? '').replaceAll(',', '.'));
    if (numero == null || numero.isNaN || numero.isInfinite || numero < 0) return 'Informe um valor valido';
    return null;
  }

  static String? nomePlano(String? valor) =>
      (valor == null || valor.trim().isEmpty) ? 'Informe o nome do plano' : null;
}
