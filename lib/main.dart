import 'package:flutter/material.dart';

// Home
import 'ui/home/home_screen.dart';

// Modules
import 'ui/url_scan/url_input_screen.dart';
import 'ui/mail_scan/mail_input_screen.dart';

void main() {
  runApp(const CyberSecurityApp());
}

class CyberSecurityApp extends StatelessWidget {
  const CyberSecurityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cyber Security App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F1A),
        colorSchemeSeed: Colors.cyanAccent,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/module1': (context) => const UrlInputScreen(),
        '/module2': (context) => const MailInputScreen(),
      },
    );
  }
}
