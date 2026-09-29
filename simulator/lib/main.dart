import 'package:flutter/material.dart';
import 'screens/simulator_screen.dart';

void main() {
  runApp(const NotificationSimulatorApp());
}

class NotificationSimulatorApp extends StatelessWidget {
  const NotificationSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SimulatorScreen(),
    );
  }
}
