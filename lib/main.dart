import 'package:flutter/material.dart';
import 'package:task_manager_flutter/app.dart';
import 'package:task_manager_flutter/data/services/background_sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundSyncService().initialize();
  runApp(const TaskManagerApp());
}
