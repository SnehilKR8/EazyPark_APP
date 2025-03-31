// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'owner_map_screen.dart';
// import 'signup_screen.dart';

// class OwnerLoginScreen extends StatefulWidget {
//   const OwnerLoginScreen({super.key});

//   @override
//   State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
// }

// class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   void _loginOwner() async {
//     try {
//       await _auth.signInWithEmailAndPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       );
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const OwnerMapScreen()),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Owner Login Failed: $e")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF2F2F2), // Light grey background
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Image.asset(
//                   'assets/images/easypark_logo_transparent.png',
//                   height: 90,
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Owner Login",
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black12,
//                         blurRadius: 8,
//                         offset: Offset(0, 4),
//                       )
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       TextField(
//                         controller: emailController,
//                         decoration: const InputDecoration(
//                           labelText: "Owner Email",
//                           prefixIcon: Icon(Icons.email),
//                         ),
//                       ),
//                       const SizedBox(height: 15),
//                       TextField(
//                         controller: passwordController,
//                         obscureText: true,
//                         decoration: const InputDecoration(
//                           labelText: "Password",
//                           prefixIcon: Icon(Icons.lock),
//                         ),
//                       ),
//                       const SizedBox(height: 25),
//                       ElevatedButton(
//                         onPressed: _loginOwner,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.greenAccent.shade400,
//                           foregroundColor: Colors.black,
//                           minimumSize: const Size(double.infinity, 48),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text("Login as Owner"),
//                       ),
//                       const SizedBox(height: 10),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (_) => const SignupScreen()),
//                           );
//                         },
//                         child: const Text(
//                           "Don't have an account? Sign up",
//                           style: TextStyle(color: Colors.black54),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'owner_map_screen.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  _OwnerLoginScreenState createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username == "admin" && password == "snehil1221") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OwnerMapScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid username or password"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Owner Login"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Welcome Owner",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Login", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
