import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fvlmyzbmfdxtutmyxcsz.supabase.co',
    publishableKey: 'sb_publishable_Oz3P2gtWDZvdql8SFHWLqQ_y-jiXjxM',
  );

  runApp(const SenkopMuzikApp());
}

class SenkopMuzikApp extends StatelessWidget {
  const SenkopMuzikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senkop Müzik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        primaryColor: const Color(0xFFD32F2F), // Senkop Kırmızısı
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
        ), // Buton ve vurguları otomatik kırmızı yapar
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// TRAFİK POLİSİ WIDGET'I
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (event == AuthChangeEvent.signedOut) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}
