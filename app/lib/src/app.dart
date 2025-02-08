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
              primaryColor: const Color(0xFF7C9A92), // Soft sage green
              primarySwatch: MaterialColor(0xFF7C9A92, {
                50: const Color(0xFFEDF1F0),
                100: const Color(0xFFD1DCD9),
                200: const Color(0xFFB3C5C0),
                300: const Color(0xFF94AEA7),
                400: const Color(0xFF7C9A92),
                500: const Color(0xFF64867D),
                600: const Color(0xFF5C7B73),
                700: const Color(0xFF526E66),
                800: const Color(0xFF48625A),
                900: const Color(0xFF364B44),
              }),
              scaffoldBackgroundColor: const Color(0xFFF5F6F8), // Light gray background
              cardTheme: CardTheme(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
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
                  backgroundColor: MaterialStateProperty.all(const Color(0xFF7C9A92)),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(const Color(0xFF7C9A92)),
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
                  borderSide: const BorderSide(color: Color(0xFF7C9A92)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              textTheme: const TextTheme(
                titleLarge: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3436),
                ),
                titleMedium: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3436),
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF636E72),
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF636E72),
                ),
              ),
            ),
            darkTheme: ThemeData.dark(),
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

                    return const HomeView();
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
