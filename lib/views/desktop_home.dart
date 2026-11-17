import 'package:flutter/material.dart';

class DesktopHome extends StatefulWidget {
  const DesktopHome({super.key});

  @override
  State<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends State<DesktopHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lambo Clicker'),
      ),
      body: const Center(
        child: Text('Welcome to Lambo Clicker!'),
      ),
    );
  }
}