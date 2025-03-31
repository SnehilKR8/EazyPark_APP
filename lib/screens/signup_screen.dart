// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'login_screen.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   _SignupScreenState createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   void _signUp() async {
//     try {
//       await _auth.createUserWithEmailAndPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       );
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (context) => LoginScreen()));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Signup Failed: ${e.toString()}")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Padding(
//           padding: EdgeInsets.all(20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Image.asset('assets/logo.jpg', height: 100), // Logo
//               SizedBox(height: 20),
//               TextField(
//                   controller: emailController,
//                   decoration: InputDecoration(labelText: "Email")),
//               TextField(
//                   controller: passwordController,
//                   decoration: InputDecoration(labelText: "Password"),
//                   obscureText: true),
//               SizedBox(height: 20),
//               ElevatedButton(onPressed: _signUp, child: Text("Sign Up")),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup Failed: ${e.toString()}")),
      );
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.black,
  //     body: Container(
  //       width: double.infinity,
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           colors: [Colors.black, const Color.fromARGB(255, 147, 45, 41)],
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //         ),
  //       ),
  //       child: Center(
  //         child: SingleChildScrollView(
  //           child: FadeTransition(
  //             opacity: _fadeAnimation,
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Image.asset('assets/logo.jpg', height: 100),
  //                 const SizedBox(height: 30),
  //                 Container(
  //                   margin: const EdgeInsets.symmetric(horizontal: 20),
  //                   padding: const EdgeInsets.all(20),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white.withOpacity(0.05),
  //                     borderRadius: BorderRadius.circular(20),
  //                     border: Border.all(
  //                       color: Colors.greenAccent.withOpacity(0.4),
  //                     ),
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: Colors.green.withOpacity(0.2),
  //                         blurRadius: 10,
  //                         spreadRadius: 2,
  //                         offset: const Offset(0, 5),
  //                       ),
  //                     ],
  //                   ),
  //                   child: Column(
  //                     children: [
  //                       Text(
  //                         "Create an Account",
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 22,
  //                           color: Colors.greenAccent,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 20),
  //                       TextField(
  //                         controller: emailController,
  //                         style: const TextStyle(color: Colors.white),
  //                         decoration: const InputDecoration(
  //                           prefixIcon:
  //                               Icon(Icons.email, color: Colors.greenAccent),
  //                           hintText: "Email",
  //                           hintStyle: TextStyle(color: Colors.white60),
  //                         ),
  //                       ),
  //                       const SizedBox(height: 15),
  //                       TextField(
  //                         controller: passwordController,
  //                         obscureText: true,
  //                         style: const TextStyle(color: Colors.white),
  //                         decoration: const InputDecoration(
  //                           prefixIcon:
  //                               Icon(Icons.lock, color: Colors.greenAccent),
  //                           hintText: "Password",
  //                           hintStyle: TextStyle(color: Colors.white60),
  //                         ),
  //                       ),
  //                       const SizedBox(height: 25),
  //                       ElevatedButton(
  //                         onPressed: _signUp,
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: Colors.greenAccent.shade400,
  //                           foregroundColor: Colors.black,
  //                           padding: const EdgeInsets.symmetric(
  //                               horizontal: 50, vertical: 14),
  //                           shape: RoundedRectangleBorder(
  //                               borderRadius: BorderRadius.circular(12)),
  //                           elevation: 8,
  //                         ),
  //                         child: const Text("Sign Up",
  //                             style: TextStyle(fontSize: 18)),
  //                       ),
  //                       TextButton(
  //                         onPressed: () {
  //                           Navigator.push(
  //                             context,
  //                             MaterialPageRoute(
  //                                 builder: (context) => const LoginScreen()),
  //                           );
  //                         },
  //                         child: const Text(
  //                           "Already have an account? Login",
  //                           style: TextStyle(color: Colors.white70),
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
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFCDD2), // Light red
              Color(0xFFFFEBEE), // Very light pink
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/easypark_logo_transparent.png',
                      height: 100),
                  const SizedBox(height: 30),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Create an Account",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            prefixIcon:
                                Icon(Icons.email, color: Colors.redAccent),
                            hintText: "Email",
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            prefixIcon:
                                Icon(Icons.lock, color: Colors.redAccent),
                            hintText: "Password",
                          ),
                        ),
                        const SizedBox(height: 25),
                        ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 6,
                          ),
                          child: const Text("Sign Up",
                              style: TextStyle(fontSize: 18)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            "Already have an account? Login",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
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
