import 'package:flutter/material.dart';
import 'package:task_manager_flutter/app.dart';
import 'package:task_manager_flutter/data/services/background_sync_service.dart';
import 'package:task_manager_flutter/data/services/preferencia_tema_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundSyncService().initialize();
  // Tema escolhido no perfil: carregado antes do primeiro frame para nao piscar.
  await PreferenciaTema.carregar();
  runApp(const TaskManagerApp());
}
