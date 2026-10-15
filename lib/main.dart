import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'screens/admin_auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set system navigation and status bar style to match the dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundPrimary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Operations Hub',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundPrimary,
        primaryColor: AppColors.primaryAccent,
        fontFamilyFallback: const [
          'Inter',
          'SF Pro Display',
          'Roboto',
          'sans-serif',
        ],
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryAccent,
          secondary: AppColors.primaryAccentLight,
          surface: AppColors.cardSurface,
          error: AppColors.warning,
        ),
        useMaterial3: true,
      ),
      home: const AdminAuthGate(),
    );
  }
}
