import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_home_screen.dart';
import 'signup_screen.dart';
import 'giver_home_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:trash_cash_fixed1/services/fcm_service.dart';
import 'collector_home_screen.dart';


class LoginScreen extends StatefulWidget {
  final String userType;
  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
 Future<void> checkAdminOrUser(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // 🔐 ADMIN
  final adminDoc = await FirebaseFirestore.instance
      .collection('admin')
      .doc(user.uid)
      .get();

  if (adminDoc.exists) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
    );
    return;
  }

  // 👤 GIVER
  final giverDoc = await FirebaseFirestore.instance
      .collection('giverusers')
      .doc(user.uid)
      .get();

  if (giverDoc.exists) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GiverHomeScreen()),
    );
    return;
  }

  // 🚚 COLLECTOR
  final collectorDoc = await FirebaseFirestore.instance
      .collection('collectorusers')
      .doc(user.uid)
      .get();

  if (collectorDoc.exists) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CollectorHomeScreen()),
    );
    return;
  }
// ❌ NO ROLE
await FirebaseAuth.instance.signOut();

if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('No role assigned to this account'),
    ),
  );
}
}


  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;


Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;
  if (isLoading) return;

  setState(() => isLoading = true);

  try {
    // 1️⃣ Firebase Authentication
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!kIsWeb) {
  await FcmService.saveFcmToken('giver');
}


    // 2️⃣ Firestore se role decide karo
    if (!mounted) return;
    await checkAdminOrUser(context);

  } on FirebaseAuthException catch (e) {
    String msg;
    if (e.code == 'user-not-found') {
      msg = 'No account found with this email';
    } else if (e.code == 'wrong-password') {
      msg = 'Incorrect password';
    } else {
      msg = e.message ?? 'Login failed';
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}
Future<void> _forgotPassword() async {
  final email = _usernameController.text.trim();

  // ❌ email empty
  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter your email first'),
      ),
    );
    return;
  }

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password reset link sent! Please check your email 📩',
        ),
      ),
    );
  } on FirebaseAuthException catch (e) {
    String msg;
    if (e.code == 'user-not-found') {
      msg = 'No account found with this email';
    } else if (e.code == 'invalid-email') {
      msg = 'Invalid email address';
    } else {
      msg = e.message ?? 'Something went wrong';
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}



  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.recycling,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRASH',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'CASH',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Title
                const Text(
                  'Enter Your Username\n& Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 40),
                // Username Field (here use email as username)
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username (Email)',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Forgotten Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      'Forgotten Password?',
                      style: TextStyle(
                        color: Colors.black87,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                // Create Account Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignupScreen(userType: widget.userType),
                        ),
                      );
                    },
                    child: const Text(
                      "Don't have an account?\nCreate a New Account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
             
              ],
            ),
          ),
        ),
      ),
    );
  }
}
