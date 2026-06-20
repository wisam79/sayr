import 'package:flutter/material.dart';

/// Splash screen showing static app icon and routing instantly.
class SplashPage extends StatefulWidget {
  /// Constructor for [SplashPage].
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Center(
        child: Image.asset(
          'assets/icons/app_icon.png',
          width: 144,
          height: 144,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
