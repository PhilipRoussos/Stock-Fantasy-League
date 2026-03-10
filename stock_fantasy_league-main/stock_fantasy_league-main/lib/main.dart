import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data_model.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCmvVpxH0479iT0J1L1jhy1MUPjtTMgVvc",
          authDomain: "stock-fantasy-league-798f7.firebaseapp.com",
          projectId: "stock-fantasy-league-798f7",
          storageBucket: "stock-fantasy-league-798f7.firebasestorage.app",
          messagingSenderId: "53658049192",
          appId: "1:53658049192:web:46647c2be6d2b236ea009d",
          measurementId: "G-PZ1Y12QFPE"
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    await AppData().loadLeaguesFromStorage();

    runApp(const MyApp());

  } catch (e) {
    print("STARTUP ERROR: $e");
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Startup Error:\n$e", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Fantasy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A0D55)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A0D55),
          foregroundColor: Colors.white,
        ),
      ),
      
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const MainNavigationScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}