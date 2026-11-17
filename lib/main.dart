import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'views/mobile_home.dart';
import 'views/desktop_home.dart';

void main() {
  runApp(const LamboClickerApp());
}

class LamboClickerApp extends StatelessWidget {
  const LamboClickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = defaultTargetPlatform == TargetPlatform.android;

    return MaterialApp(
      title: 'Lambo Clicker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: isMobile ? const MobileHome() : const DesktopHome(),
    );
  }
}
