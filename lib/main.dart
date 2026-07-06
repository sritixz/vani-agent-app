import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/screens/splash_screen.dart';
import 'package:vani_app/screens/auth/login_screen.dart';
import 'package:vani_app/screens/auth/forgot_password_screen.dart';
import 'package:vani_app/screens/auth/reset_password_screen.dart';
import 'package:vani_app/screens/auth/google_callback_screen.dart';
import 'package:vani_app/screens/main_shell.dart';
import 'package:vani_app/screens/phone_numbers/available_phone_numbers_screen.dart';
import 'package:vani_app/screens/whatsapp/whatsapp_inbox_screen.dart';
import 'package:vani_app/screens/integrations/integrations_screen.dart';
import 'package:vani_app/screens/integrations/meta_ads_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaniAgent',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      // Named routes for simple screens
      routes: {
        '/login': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialEmail = args is String ? args : null;
          return LoginScreen(initialEmail: initialEmail);
        },
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final email = args is String ? args : '';
          return ResetPasswordScreen(email: email);
        },
        '/home': (context) => const MainShell(),
        '/available-phone-numbers': (context) => const AvailablePhoneNumbersScreen(),
        '/whatsapp-inbox': (context) => const WhatsAppInboxScreen(),
        '/integrations': (context) => const IntegrationsScreen(),
        '/meta-ads': (context) => const MetaAdsScreen(),
      },
      // onGenerateRoute handles routes that carry dynamic parameters,
      // including the Google OAuth deep link: vaniapp://auth/google/callback?code=...&state=...
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';

        if (name == '/auth/google/callback' ||
            name.startsWith('/auth/google/callback')) {
          // On web, query params come from Uri.base.
          // On mobile, Flutter passes the full URI string as the route name
          // (e.g. "vaniapp://auth/google/callback?code=abc&state=xyz").
          String? code;
          String? state;
          String? error;

          // Try to parse query params from the route name itself (mobile deep link)
          try {
            final uri = Uri.parse(name);
            code = uri.queryParameters['code'];
            state = uri.queryParameters['state'];
            error = uri.queryParameters['error'];
          } catch (_) {
            // fallback: no query params in route name
          }

          // On web, fall back to Uri.base
          if (code == null && error == null) {
            try {
              final uri = Uri.base;
              code = uri.queryParameters['code'];
              state = uri.queryParameters['state'];
              error = uri.queryParameters['error'];
            } catch (_) {}
          }

          return MaterialPageRoute(
            builder: (_) => GoogleCallbackScreen(
              code: code,
              state: state,
              error: error,
            ),
            settings: settings,
          );
        }

        return null; // Let the routes table handle anything else
      },
    );
  }
}
