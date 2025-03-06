import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/profile/profile_view.dart';
import 'views/appointments/appointment_list_view.dart';
import 'views/appointments/appointment_form_view.dart';
import 'views/resources/resource_list_view.dart';
import 'views/resources/resource_details_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'views/home/home_view.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.settingsController,
  }) : super(key: key);

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: Consumer<AuthController>(
        builder: (context, authController, _) {
          return MaterialApp(
            title: 'Your App',
            theme: ThemeData(
              primaryColor: const Color(0xFF0F3DD6),
              primarySwatch: MaterialColor(0xFF0F3DD6, {
                50: const Color(0xFFE8EDF9),  // Lightest shade
                100: const Color(0xFFC2D1F0),
                200: const Color(0xFF99B3E7),
                300: const Color(0xFF7095DE),
                400: const Color(0xFF527ED8),
                500: const Color(0xFF0F3DD6),  // Primary color
                600: const Color(0xFF0D37C1),
                700: const Color(0xFF0B2FA7),
                800: const Color(0xFF09278D),
                900: const Color(0xFF061960),  // Darkest shade
              }),
              scaffoldBackgroundColor: const Color(0xFFF8F9FE), // Light blue-tinted background
              cardTheme: CardTheme(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(const Color(0xFF1C0FD6)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1C0FD6)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              textTheme: const TextTheme(
                titleLarge: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1F36), // Dark text for headings
                ),
                titleMedium: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1F36),
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A5578), // Slightly lighter for body text
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A5578),
                ),
              ),
              primaryTextTheme: const TextTheme(
                titleLarge: TextStyle(color: Colors.white),
                titleMedium: TextStyle(color: Colors.white),
                titleSmall: TextStyle(color: Colors.white),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ButtonStyle(
                  elevation: MaterialStateProperty.all(0),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  backgroundColor: MaterialStateProperty.all(const Color(0xFF1C0FD6)),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                ),
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: const Color(0xFF1C0FD6),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF1C0FD6),
                secondary: Color(0xFF5952D8),
              ),
            ),
            themeMode: settingsController.themeMode,
            home: Builder(
              builder: (context) {
                return StreamBuilder<bool>(
                  stream: authController.authStateStream,
                  builder: (context, snapshot) {
                    if (authController.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!authController.isAuthenticated) {
                      return const LoginView();
                    }

                    // Check if user is a counselor
                    final isCounselor = authController.user?['roles']?.contains('counselor') ?? false;
                    return isCounselor 
                        ? const AppointmentListView() 
                        : const HomeView();
                  },
                );
              },
            ),
            onGenerateRoute: (RouteSettings settings) {
              if (settings.name == ResourceDetailsView.routeName) {
                return MaterialPageRoute(
                  builder: (context) => ResourceDetailsView(
                    key: ValueKey(settings.arguments),
                    resourceId: settings.arguments as String,
                  ),
                );
              }
              return null;
            },
            routes: {
              '/login': (context) => const LoginView(),
              '/home': (context) => const HomeView(),
              '/register': (context) => const RegisterView(),
              '/profile': (context) => const ProfileView(),
              '/appointments': (context) => const AppointmentListView(),
              '/appointments/create': (context) => const AppointmentFormView(),
              '/appointment_form': (context) => const AppointmentFormView(),
              '/resources': (context) => const ResourceListView(),
              '/settings': (context) => SettingsView(controller: settingsController),
            },
          );
        },
      ),
    );
  }
}

