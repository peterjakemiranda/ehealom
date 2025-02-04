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
    // Glue the SettingsController to the MaterialApp.
    //
    // The AnimatedBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(
            // Calm, mindful color scheme
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

          // Update route generation to include auth check
          initialRoute: '/',
          onGenerateRoute: (RouteSettings routeSettings) {
            debugPrint('Generating route for: ${routeSettings.name}');
            
            return MaterialPageRoute(
              settings: routeSettings,
              builder: (context) {
                final authController = context.watch<AuthController>();
                
                if (authController.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Allow access to login and register routes without authentication
                if (!authController.isAuthenticated && 
                    routeSettings.name != LoginView.routeName &&
                    routeSettings.name != RegisterView.routeName) {
                  return const LoginView();
                }

                // Route handling
                switch (routeSettings.name) {
                  case LoginView.routeName:
                    return const LoginView();
                  case RegisterView.routeName:
                    return const RegisterView();
                  case '/':
                  case HomeView.routeName:
                    return const HomeView();
                  case ProfileView.routeName:
                    return const ProfileView();
                  case AppointmentListView.routeName:
                    return const AppointmentListView();
                  case AppointmentFormView.routeName:
                    return const AppointmentFormView();
                  case ResourceListView.routeName:
                    return const ResourceListView();
                  case ResourceDetailsView.routeName:
                    final args = routeSettings.arguments as String;
                    return ResourceDetailsView(resourceId: args);
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  default:
                    return const HomeView();
                }
              },
            );
          },
        );
      },
    );
  }
}
