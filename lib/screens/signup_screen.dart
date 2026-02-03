import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'giver_home_screen.dart';
import 'collector_home_screen.dart';

class SignupScreen extends StatefulWidget {
  final String userType;

  const SignupScreen({super.key, required this.userType});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (isLoading) return;
    setState(() => isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final address = _addressController.text.trim();


    try {
      // 1) Create Firebase Auth User
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Ensure user object exists
      final user = cred.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup failed: no user created.")),
        );
        setState(() => isLoading = false);
        return;
      }

      final uid = user.uid;

      // 2) Decide collection based on role
      final String collectionName =
          (widget.userType.toLowerCase() == 'giver') ? 'giverusers' : 'collectorusers';

      // Prepare payload
      final Map<String, dynamic> payload = {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address, 
        'userType': widget.userType,
        'points': 0,
        'scanned': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 3) Save user data in chosen collection using doc(uid)
      await FirebaseFirestore.instance.collection(collectionName).doc(uid).set(payload);

      // 4) Reload currentUser to make sure auth state is fresh (edge-case)
      try {
        await FirebaseAuth.instance.currentUser?.reload();
      } catch (_) {
        // ignore
      }

      // 5) Navigate to correct Home screen (only after everything completed)
      if (!mounted) return;

      if (widget.userType.toLowerCase() == 'giver') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GiverHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CollectorHomeScreen()),
        );
      }
      // Note: navigation occurs immediately after successful save.
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'email-already-in-use') {
        msg = "This email is already registered.";
      } else if (e.code == 'weak-password') {
        msg = "Password should be at least 6 characters.";
      } else if (e.code == 'invalid-email') {
        msg = "Please enter a valid email address.";
      } else {
        msg = e.message ?? "Signup failed.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LOGO (same)
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.recycling,
                          color: Colors.white, size: 25),
                    ),
                    const SizedBox(width: 10),
                  
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Create Your\nAccount',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),

                // NAME FIELD
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    enabledBorder:
                        UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder:
                        UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter full name" : null,
                ),

                const SizedBox(height: 20),

                // EMAIL FIELD
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    enabledBorder:
                        UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder:
                        UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter email" : null,
                ),

                const SizedBox(height: 20),

                // PHONE FIELD
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    enabledBorder:
                        UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder:
                        UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter phone number" : null,
                ),
                const SizedBox(height: 20),
                // ADDRESS FIELD
                TextFormField(
  controller: _addressController,
  maxLines: 2,
  decoration: const InputDecoration(
    labelText: 'Address',
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.green),
    ),
  ),
  validator: (value) =>
      value == null || value.isEmpty ? "Please enter address" : null,
),
                const SizedBox(height: 20),

                // PASSWORD FIELD
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    enabledBorder:
                        UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder:
                        UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter password" : null,
                ),

                const SizedBox(height: 20),

                // SIGNUP BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSignup,
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
                            'SIGN UP',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const Spacer(),

                // Already HAVE ACCOUNT → LOGIN
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Already have an account?\nLogin Here",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
