import 'package:flutter/material.dart';
import 'widgets/web_camera_widget.dart';

void main() {
  runApp(const VeeApp());
}

class VeeApp extends StatelessWidget {
  const VeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vee',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111111),
        primaryColor: Colors.deepPurple,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const VeeHomePage(),
    );
  }
}

class VeeHomePage extends StatelessWidget {
  const VeeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vee AI Assistant'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // 👁️ Camera Preview Placeholder
          Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              child: WebCameraWidget(),
            ),
          ),
          const SizedBox(height: 40),
          // 🎤 Mic Button
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Trigger voice input here
            },
            icon: const Icon(Icons.mic),
            label: const Text('Ask a Question'),
          ),
          const SizedBox(height: 20),
          // 🔊 Text Response Placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Response will be spoken here...',
              style: TextStyle(fontSize: 16, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
