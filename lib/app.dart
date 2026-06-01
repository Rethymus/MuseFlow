import 'package:flutter/material.dart';

/// Root application widget for MuseFlow.
///
/// Task 2 will replace this with the full go_router + StatefulShellRoute configuration.
class MuseFlowApp extends StatelessWidget {
  const MuseFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuseFlow 灵韵',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('MuseFlow 灵韵 - Loading...'),
        ),
      ),
    );
  }
}
