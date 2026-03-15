import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/auth/auth_landing_page.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F2B3A),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Aurora Bay Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F1E8),
        textTheme: GoogleFonts.soraTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF6F1E8),
          elevation: 0,
          titleTextStyle: GoogleFonts.fraunces(
            color: const Color(0xFF1C1A18),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1C1A18)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFDF9F3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AuthLanding(),
    );
  }
}
