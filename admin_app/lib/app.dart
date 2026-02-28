import 'package:flutter/material.dart';
import 'package:admin_app/core/constants/app_colors.dart';
import 'package:admin_app/core/constants/admin_config.dart';
import 'package:admin_app/core/services/auth_service.dart';
import 'package:admin_app/core/services/connectivity_service.dart';
import 'package:admin_app/core/widgets/session_scope.dart';
import 'package:admin_app/features/auth/screens/pin_screen.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      authService: AuthService(),
      connectivityService: ConnectivityService(),
      child: MaterialApp(
      title: AdminConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        cardTheme: const CardThemeData(
          color: AppColors.cardBg,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
          // Do not set foregroundColor here — screens with light AppBar (e.g. cardBg)
          // would inherit white and the back button would be invisible. Let default
          // (ColorScheme) provide contrast; screens using primary bar set foregroundColor
          // explicitly (e.g. Colors.white) where needed.
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: AppColors.cardBg,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const PinScreen(),
      ),
    );
  }
}
