import 'package:flutter/material.dart';
import 'screens/splash/splash_page.dart';
import 'core/theme/app_theme.dart';


class TunceliUlasimApp extends StatelessWidget {
  const TunceliUlasimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tunceli Ulaşım',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}