// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'screens/login_screen.dart';
// import 'screens/maps_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   print("🔥 Flutter binding initialized");

//   try {
//     if (Firebase.apps.isEmpty) {
//       print("⏳ Trying to initialize Firebase...");
//       await Firebase.initializeApp(
//         options: FirebaseOptions(
//           apiKey: "AIzaSyAQc0751QjtX8Hmd6Om5dsraSutf9q_kQw",
//           authDomain: "eazypark-4fbc6.firebaseapp.com",
//           projectId: "eazypark-4fbc6",
//           storageBucket: "eazypark-4fbc6.appspot.com",
//           messagingSenderId: "306837880069",
//           appId: "1:306837880069:web:a2776bd3441c85937ccb6c",
//           measurementId: "G-YMX5ZH5FEC",
//         ),
//       ).timeout(Duration(seconds: 10));
//       print("✅ Firebase initialized");
//     } else {
//       print("⚠️ Firebase already initialized");
//     }
//   } catch (e, stackTrace) {
//     print("❌ Firebase init failed: $e");
//     print("🔍 Stacktrace: $stackTrace");
//   }

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'EasyPark',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//       ),
//       home: const AuthCheck(),
//     );
//   }
// }

// class AuthCheck extends StatelessWidget {
//   const AuthCheck({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasData) {
//           return const MapsScreen();
//         } else {
//           return const LoginScreen();
//         }
//       },
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/owner_login_screen.dart'; // <-- ADD THIS LINE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🔥 Flutter binding initialized");

  try {
    if (Firebase.apps.isEmpty) {
      print("⏳ Trying to initialize Firebase...");
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyAQc0751QjtX8Hmd6Om5dsraSutf9q_kQw",
          authDomain: "eazypark-4fbc6.firebaseapp.com",
          projectId: "eazypark-4fbc6",
          storageBucket: "eazypark-4fbc6.appspot.com",
          messagingSenderId: "306837880069",
          appId: "1:306837880069:web:a2776bd3441c85937ccb6c",
          measurementId: "G-YMX5ZH5FEC",
        ),
      ).timeout(Duration(seconds: 10));
      print("✅ Firebase initialized");
    } else {
      print("⚠️ Firebase already initialized");
    }
  } catch (e, stackTrace) {
    print("❌ Firebase init failed: $e");
    print("🔍 Stacktrace: $stackTrace");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyPark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const RoleSelector(),
    );
  }
}

class RoleSelector extends StatelessWidget {
  const RoleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EasyPark")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Login as User"),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const AuthCheck()));
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Login as Owner"),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OwnerLoginScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const MapsScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
