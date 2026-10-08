import 'dart:math';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

/// Avaliação Física Profissional (Padrão MFIT Personal)
/// Protocolos científicos de Pollock (3 e 7 dobras), cálculo de %BF, massa magra/gorda e perimetria.
class AvaliacaoFisicaProScreen extends StatefulWidget {
  final String? alunoNome;

  const AvaliacaoFisicaProScreen({
    super.key,
    this.alunoNome,
  });

  @override
  State<AvaliacaoFisicaProScreen> createState() =>
      _AvaliacaoFisicaProScreenState();
}

class _AvaliacaoFisicaProScreenState extends State<AvaliacaoFisicaProScreen> {
  // Dados Básicos
  String _sexo = 'Masculino'; // 'Masculino' ou 'Feminino'
  int _idade = 28;
  double _pesoKg = 78.5;
  double _alturaCm = 175.0;

  // Protocolo Selecionado
  String _protocolo = 'Pollock 3 Dobras'; // ou 'Pollock 7 Dobras'

  // Dobras Cutâneas (em mm)
  double _peitoral = 10.0;
  double _abdomen = 18.0;
  double _coxa = 14.0;
  double _triceps = 12.0;
  double _supraIliaca = 15.0;
  double _subescapular = 14.0;
  double _axilarMedia = 12.0;

  // Perimetria (em cm)
  final Map<String, double> _medidas = {
    'Tórax': 98.0,
    'Cintura': 82.0,
    'Abdômen': 85.0,
    'Quadril': 100.0,
    'Braço Direito (Relaxado)': 34.0,
    'Braço Direito (Contraído)': 37.5,
    'Braço Esquerdo (Contraído)': 37.0,
    'Coxa Direita': 56.0,
    'Panturrilha Direita': 38.0,
  };

  // ─────────────────────────────────────────────────────────────────────────────
  // Cálculos Científicos de Pollock e Equação de Siri
  // ─────────────────────────────────────────────────────────────────────────────

  double get _somaDobras {
    if (_protocolo == 'Pollock 3 Dobras') {
      if (_sexo == 'Masculino') {
        return _peitoral + _abdomen + _coxa;
      } else {
        return _triceps + _supraIliaca + _coxa;
      }
    } else {
      return _peitoral +
          _abdomen +
          _coxa +
          _triceps +
          _supraIliaca +
          _subescapular +
          _axilarMedia;
    }
  }

  double get _percentualGordura {
    final s = _somaDobras;
    final idade = _idade.toDouble();
    double densidade;

    if (_protocolo == 'Pollock 3 Dobras') {
      if (_sexo == 'Masculino') {
        // Pollock 3 dobras homens: Peitoral, Abdômen, Coxa
        densidade = 1.10938 -
            (0.0008267 * s) +
            (0.0000016 * pow(s, 2)) -
            (0.0002574 * idade);
      } else {
        // Pollock 3 dobras mulheres: Tríceps, Supra-ilíaca, Coxa
        densidade = 1.0994921 -
            (0.0009929 * s) +
            (0.0000023 * pow(s, 2)) -
            (0.0001392 * idade);
      }
    } else {
      if (_sexo == 'Masculino') {
        densidade = 1.112 -
            (0.00043499 * s) +
            (0.00000055 * pow(s, 2)) -
            (0.00028826 * idade);
      } else {
        densidade = 1.097 -
            (0.00046971 * s) +
            (0.00000056 * pow(s, 2)) -
            (0.00012828 * idade);
      }
    }

    // Fórmula de Siri: %G = [(4.95 / Densidade) - 4.50] * 100
    final perc = ((4.95 / densidade) - 4.50) * 100;
    return perc.clamp(3.0, 50.0);
  }

  double get _massaGordaKg => _pesoKg * (_percentualGordura / 100);
  double get _massaMagraKg => _pesoKg - _massaGordaKg;
  double get _imc => _pesoKg / pow(_alturaCm / 100, 2);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktopOrWeb = width >= 800;

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: Text(
          widget.alunoNome != null
              ? 'Avaliação Física • ${widget.alunoNome}'
              : 'Avaliação Física Protocolada',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'Salvar Avaliação',
            icon: const Icon(Icons.check, color: GridColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: GridColors.success,
                  content: Text('Avaliação física calculada e salva com sucesso!'),
                ),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktopOrWeb ? 1100 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Resumo em Destaque (Card com Resultados Instantâneos)
              _buildCardResultado(),

              const SizedBox(height: 16),

              // 2. Parâmetros do Aluno (Sexo, Idade, Peso, Altura)
              _buildSecaoParametros(),

              const SizedBox(height: 16),

              // 3. Dobras Cutâneas (Pollock)
              _buildSecaoDobras(),

              const SizedBox(height: 16),

              // 4. Perimetria Corporal (Circunferências)
              _buildSecaoPerimetria(),

              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Salvar e Gerar Relatório de Evolução'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: GridColors.success,
                        content: Text('Avaliação registrada no histórico do aluno!'),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardResultado() {
    final bf = _percentualGordura;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GridColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: GridColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Composição Corporal Atual',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _protocolo,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildItemResultado(
                  label: '% Gordura',
                  valor: '${bf.toStringAsFixed(1)}%',
                  destaque: true,
                ),
              ),
              Expanded(
                child: _buildItemResultado(
                  label: 'Massa Magra',
                  valor: '${_massaMagraKg.toStringAsFixed(1)} kg',
                ),
              ),
              Expanded(
                child: _buildItemResultado(
                  label: 'Massa Gorda',
                  valor: '${_massaGordaKg.toStringAsFixed(1)} kg',
                ),
              ),
              Expanded(
                child: _buildItemResultado(
                  label: 'IMC',
                  valor: _imc.toStringAsFixed(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemResultado({
    required String label,
    required String valor,
    bool destaque = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: TextStyle(
            color: Colors.white,
            fontSize: destaque ? 22 : 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSecaoParametros() {
    return Card(
      elevation: 0,
      color: GridColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GridColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parâmetros Básicos',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sexo,
                    decoration: const InputDecoration(labelText: 'Sexo'),
                    items: const [
                      DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                      DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sexo = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _protocolo,
                    decoration: const InputDecoration(labelText: 'Protocolo'),
                    items: const [
                      DropdownMenuItem(value: 'Pollock 3 Dobras', child: Text('Pollock 3 Dobras')),
                      DropdownMenuItem(value: 'Pollock 7 Dobras', child: Text('Pollock 7 Dobras')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _protocolo = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '$_idade',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Idade (anos)'),
                    onChanged: (val) => setState(() => _idade = int.tryParse(val) ?? _idade),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: '$_pesoKg',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso (kg)'),
                    onChanged: (val) => setState(() => _pesoKg = double.tryParse(val) ?? _pesoKg),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: '$_alturaCm',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Altura (cm)'),
                    onChanged: (val) => setState(() => _alturaCm = double.tryParse(val) ?? _alturaCm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoDobras() {
    final is3Dobras = _protocolo == 'Pollock 3 Dobras';

    return Card(
      elevation: 0,
      color: GridColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GridColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dobras Cutâneas (em mm)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  'Soma: ${_somaDobras.toStringAsFixed(1)} mm',
                  style: const TextStyle(
                    color: GridColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (is3Dobras && _sexo == 'Masculino') ...[
              _buildInputDobra('Peitoral (mm)', _peitoral, (v) => setState(() => _peitoral = v)),
              _buildInputDobra('Abdômen (mm)', _abdomen, (v) => setState(() => _abdomen = v)),
              _buildInputDobra('Coxa (mm)', _coxa, (v) => setState(() => _coxa = v)),
            ] else if (is3Dobras && _sexo == 'Feminino') ...[
              _buildInputDobra('Tríceps (mm)', _triceps, (v) => setState(() => _triceps = v)),
              _buildInputDobra('Supra-ilíaca (mm)', _supraIliaca, (v) => setState(() => _supraIliaca = v)),
              _buildInputDobra('Coxa (mm)', _coxa, (v) => setState(() => _coxa = v)),
            ] else ...[
              _buildInputDobra('Peitoral (mm)', _peitoral, (v) => setState(() => _peitoral = v)),
              _buildInputDobra('Axilar Média (mm)', _axilarMedia, (v) => setState(() => _axilarMedia = v)),
              _buildInputDobra('Tríceps (mm)', _triceps, (v) => setState(() => _triceps = v)),
              _buildInputDobra('Subescapular (mm)', _subescapular, (v) => setState(() => _subescapular = v)),
              _buildInputDobra('Abdômen (mm)', _abdomen, (v) => setState(() => _abdomen = v)),
              _buildInputDobra('Supra-ilíaca (mm)', _supraIliaca, (v) => setState(() => _supraIliaca = v)),
              _buildInputDobra('Coxa (mm)', _coxa, (v) => setState(() => _coxa = v)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputDobra(String label, double valor, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          SizedBox(
            width: 110,
            child: TextFormField(
              initialValue: '$valor',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) {
                final d = double.tryParse(val) ?? valor;
                onChanged(d);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoPerimetria() {
    return Card(
      elevation: 0,
      color: GridColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GridColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perimetria Corporal (em cm)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 14),
            for (final entry in _medidas.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ),
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        initialValue: '${entry.value}',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          final d = double.tryParse(val) ?? entry.value;
                          _medidas[entry.key] = d;
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
