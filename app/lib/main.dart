import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'src/controllers/auth_controller.dart';
import 'src/config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment first
  await Environment.initialize(Environment.dev);
  
  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  // Set environment
  Environment.currentEnvironment = Environment.dev; // or Environment.prod for production

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: MyApp(settingsController: settingsController),
    ),
  );
}
