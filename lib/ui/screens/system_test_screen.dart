import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class SystemTestScreen extends StatefulWidget {
  const SystemTestScreen({super.key});

  @override
  _SystemTestScreenState createState() => _SystemTestScreenState();
}

class _SystemTestScreenState extends State<SystemTestScreen> {
  final List<String> _logs = [];
  bool _isRunning = false;
  double _progress = 0.0;
  String _progressLabel = '';
  int _totalTests = 0;
  int _testsRun = 0;

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
    });
  }

  void _updateProgress(String label) {
    setState(() {
      _testsRun++;
      _progress = _testsRun / _totalTests;
      _progressLabel = label;
    });
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
      _progress = 0.0;
      _progressLabel = '';
      _testsRun = 0;
    });

    _addLog('🔵 INICIANDO TESTES DE INTEGRAÇÃO...');

        final userInfo = await AuthUtility.getUserInfo();
    final token = userInfo?.token;
    if (token == null) {
      _addLog('❌ Erro: Token de autenticação não encontrado.');
      setState(() {
        _isRunning = false;
      });
      return;
    }
    _addLog('🔑 Token de autenticação obtido.');

    final headers = {
      'Content-Type': 'application/json;charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    String uniqueIso() => DateTime.now().toIso8601String();
    String uniqueName(String base) =>
        '$base ${DateTime.now().millisecondsSinceEpoch}';

    final scenarios = [
      // --- CALENDÁRIO ---
      CrudScenario(
        name: 'Calendário',
        endpoint: '${ApiLinks.baseUrl}/calendario',
        createPayloadFactory: () => {
          "titulo": uniqueName("Evento Teste"),
          "descricao": "Teste Automatizado",
          "dataInicio": uniqueIso(),
          "dataFim":
              DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          "diaTodo": false
        },
        updatePayloadFactory: (id) => {"titulo": "Evento Teste ATUALIZADO"},
      ),
      // ... (rest of the scenarios)
    ];

    _totalTests = scenarios.length * 4; // 4 operations per scenario

    for (final scenario in scenarios) {
      _addLog('\n📱 Tela: ${scenario.name}');
      int? createdId;

      // --- READ (GET) ---
      _updateProgress('GET ${scenario.name}');
      try {
        _addLog('   👉 [GET] ${scenario.endpoint}');
        final response =
            await http.get(Uri.parse(scenario.endpoint), headers: headers);
        if (response.statusCode == 200) {
          _addLog('   ✅ [GET] ${scenario.name}: SUCESSO');
        } else {
          _addLog(
              '   ❌ [GET] ${scenario.name}: FALHA (${response.statusCode})');
        }
      } catch (e) {
        _addLog('   ❌ [GET] ${scenario.name}: ERRO ($e)');
      }

      // --- CREATE (POST) ---
      _updateProgress('POST ${scenario.name}');
      try {
        final payload = scenario.createPayloadFactory();
        _addLog('   👉 [POST] ${scenario.endpoint}');
        final response = await http.post(
          Uri.parse(scenario.endpoint),
          headers: headers,
          body: jsonEncode(payload),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final body = jsonDecode(response.body);
          createdId = body[scenario.idField] ?? body['data']?[scenario.idField];
          if (createdId != null) {
            _addLog('   ✅ [POST] ${scenario.name}: SUCESSO (ID: $createdId)');
          } else {
            _addLog('   ❌ [POST] ${scenario.name}: FALHA (ID não encontrado na resposta)');
          }
        } else {
          _addLog(
              '   ❌ [POST] ${scenario.name}: FALHA (${response.statusCode})');
        }
      } catch (e) {
        _addLog('   ❌ [POST] ${scenario.name}: ERRO ($e)');
      }

      // --- UPDATE (PUT) ---
      _updateProgress('PUT ${scenario.name}');
      if (createdId != null) {
        try {
          final payload = scenario.updatePayloadFactory(createdId);
          _addLog('   👉 [PUT] ${scenario.endpoint}/$createdId');
          final response = await http.put(
            Uri.parse('${scenario.endpoint}/$createdId'),
            headers: headers,
            body: jsonEncode(payload),
          );
          if (response.statusCode == 200 || response.statusCode == 204) {
            _addLog('   ✅ [PUT] ${scenario.name}: SUCESSO');
          } else {
            _addLog(
                '   ❌ [PUT] ${scenario.name}: FALHA (${response.statusCode})');
          }
        } catch (e) {
          _addLog('   ❌ [PUT] ${scenario.name}: ERRO ($e)');
        }
      } else {
        _addLog('   ⚠️ [PUT] ${scenario.name}: IGNORADO (sem ID)');
      }

      // --- DELETE (DELETE) ---
      _updateProgress('DELETE ${scenario.name}');
      if (createdId != null) {
        try {
          _addLog('   👉 [DELETE] ${scenario.endpoint}/$createdId');
          final response = await http.delete(
            Uri.parse('${scenario.endpoint}/$createdId'),
            headers: headers,
          );
          if (response.statusCode == 200 || response.statusCode == 204) {
            _addLog('   ✅ [DELETE] ${scenario.name}: SUCESSO');
          } else {
            _addLog(
                '   ❌ [DELETE] ${scenario.name}: FALHA (${response.statusCode})');
          }
        } catch (e) {
          _addLog('   ❌ [DELETE] ${scenario.name}: ERRO ($e)');
        }
      } else {
        _addLog('   ⚠️ [DELETE] ${scenario.name}: IGNORADO (sem ID)');
      }
    }

    _addLog('\n✅ Testes concluídos.');

    setState(() {
      _isRunning = false;
      _progressLabel = 'Completo!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testes de Integração'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runTests,
              child: Text(_isRunning ? 'Executando...' : 'Iniciar Testes'),
            ),
            const SizedBox(height: 16),
            if (_isRunning || _progress > 0) ...[
              LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
              ),
              const SizedBox(height: 8),
              Text('${(_progress * 100).toStringAsFixed(0)}% - $_progressLabel'),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    Color color = Colors.black;
                    if (log.contains('SUCESSO')) {
                      color = Colors.green;
                    } else if (log.contains('FALHA') || log.contains('ERRO')) {
                      color = Colors.red;
                    } else if (log.contains('IGNORADO')) {
                      color = Colors.orange;
                    }
                    return Text(log, style: TextStyle(color: color));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CrudScenario {
  final String name;
  final String endpoint;
  final Map<String, dynamic> Function() createPayloadFactory;
  final Map<String, dynamic> Function(int id) updatePayloadFactory;
  final String idField;

  CrudScenario({
    required this.name,
    required this.endpoint,
    required this.createPayloadFactory,
    required this.updatePayloadFactory,
    this.idField = 'id',
  });
}
