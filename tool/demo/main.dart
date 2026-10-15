// Servidor de captura isolado: flutter run -d web-server --web-port 8092 -t tool/demo/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/screens/fitness/treinos_hub_screen.dart';
import 'package:task_manager_flutter/ui/widgets/fitness_graficos_hub.dart';
import 'dados_demo_eu_atleta.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final fonte = FontLoader('Roboto')..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  await fonte.load();
  final demo = DadosDemoEuAtleta(DateTime.now().subtract(const Duration(hours: 1)));
  // Fixture de captura: usa memoria para jamais tocar dados reais.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'appacademia_planos_treino_v1': jsonEncode([demo.plano.toMap()]),
    'appacademia_sessoes_treino_v1': jsonEncode(demo.sessoes.reversed.map((s) => s.toMap()).toList()),
  });
  final tela = Uri.base.queryParameters['tela'];
  runApp(MaterialApp(debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669))),
    home: tela == null ? const LoginScreen() : Scaffold(body: Column(children: [
      Container(width: double.infinity, color: const Color(0xFF064E3B),
        padding: const EdgeInsets.all(16), child: const Text(
          'EU ATLETA  •  DEMONSTRAÇÃO\nDados de exemplo — nenhuma conta real',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      Expanded(child: tela == 'hub'
        ? SingleChildScrollView(padding: const EdgeInsets.all(24),
            child: FitnessGraficosHub(dados: Future.value(demo.graficos)))
        : const TreinosHubScreen()),
    ])),
  ));
}
