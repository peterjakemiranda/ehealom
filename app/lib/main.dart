import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'src/controllers/auth_controller.dart';
import 'src/config/env.dart';
import 'firebase_options.dart'; // Assuming this file exists
import 'src/services/firebase_messaging_service.dart';
import 'src/api/api_service.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment first
  await Environment.initialize(Environment.dev);
  
  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  // Set environment
  Environment.currentEnvironment = Environment.dev;

  // Create API service
  final apiService = ApiService();

  // Initialize Firebase only if not running on simulator
  FirebaseMessagingService? messagingService;
  if (!Platform.isIOS || !Platform.environment.containsKey('SIMULATOR_HOST_HOME')) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Create and initialize Firebase messaging service
    messagingService = FirebaseMessagingService(apiService);
    await messagingService.initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        Provider<ApiService>.value(value: apiService),
        if (messagingService != null)
          Provider<FirebaseMessagingService>.value(value: messagingService),
      ],
      child: MyApp(settingsController: settingsController),
    ),
  );
}
