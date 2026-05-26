import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/api/api_client.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/otp_verification_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (_, themeMode, __) => _buildApp(themeMode),
    );
  }

  Widget _buildApp(ThemeMode themeMode) {
    return MaterialApp(
      title: 'Elan Ledgers',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Check if user is logged in
        final isLoggedIn = ApiClient.instance.isLoggedIn;
        
        // If trying to access root, decide based on auth state
        if (settings.name == '/') {
          if (isLoggedIn) {
            return MaterialPageRoute(
              builder: (context) => const DashboardPage(),
              settings: settings,
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => const OnboardingPage(),
              settings: settings,
            );
          }
        }
        
        // Handle other routes
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (context) => const LoginPage(),
              settings: settings,
            );
          case '/register':
            return MaterialPageRoute(
              builder: (context) => const RegisterPage(),
              settings: settings,
            );
          case '/forgot-password':
            return MaterialPageRoute(
              builder: (context) => const ForgotPasswordPage(),
              settings: settings,
            );
          case '/otp-verification':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                username: args?['username'] ?? '',
                phone: args?['phone'],
              ),
              settings: settings,
            );
          case '/dashboard':
            return MaterialPageRoute(
              builder: (context) => const DashboardPage(),
              settings: settings,
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => const ProfilePage(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const OnboardingPage(),
              settings: settings,
            );
        }
      },
    );
  }
}
