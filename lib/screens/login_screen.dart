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
  // --- Logic remains exactly same ---
  Future<void> checkAdminOrUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    String? token;
    try {
      token = await FcmService.getFcmToken();
    } catch (_) {
      token = null;
    }

    final collectorRef = FirebaseFirestore.instance.collection('collectorusers').doc(uid);
    final collectorDoc = await collectorRef.get();

    if (collectorDoc.exists) {
      final Map<String, dynamic> updateData = {
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (token != null) updateData['fcmToken'] = token;
      await collectorRef.set(updateData, SetOptions(merge: true));

      final isAdmin = collectorDoc.data()?['isAdmin'] == true;
      if (isAdmin) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CollectorHomeScreen()));
      }
      return;
    }

    final giverRef = FirebaseFirestore.instance.collection('giverusers').doc(uid);
    final giverDoc = await giverRef.get();

    if (giverDoc.exists) {
      await giverRef.set({
        'fcmToken': token,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GiverHomeScreen()));
      return;
    }

    await FirebaseAuth.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid role assigned to this account')));
    }
  }

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!kIsWeb) await FcmService.init();
      if (!mounted) return;
      await checkAdminOrUser(context);
    } on FirebaseAuthException catch (e) {
      String msg = e.code == 'user-not-found' ? 'No account found with this email' : (e.code == 'wrong-password' ? 'Incorrect password' : e.message ?? 'Login failed');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _usernameController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email first')));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent! Check your email 📩')));
    } on FirebaseAuthException catch (e) {
      String msg = e.code == 'user-not-found' ? 'No account found' : (e.code == 'invalid-email' ? 'Invalid email' : 'Something went wrong');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      backgroundColor: const Color(0xFFF4F9F4), // Fresh minty white
      body: Stack(
        children: [
          // Background UI Decoration
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(radius: 150, backgroundColor: Colors.green.withOpacity(0.05)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 30),
                    
                    // Logo Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                              ],
                            ),
                            child: const Icon(Icons.recycling_rounded, size: 45, color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(height: 16),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(text: 'TRASH ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32), letterSpacing: 1)),
                                TextSpan(text: 'CASH', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.orange)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                    ),
                    const Text('Login to continue your journey', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 40),

                    // Modern Input Fields
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Email Address',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 8,
                          shadowColor: Colors.green.withOpacity(0.3),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                            : const Text('LOGIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),

                    const SizedBox(height: 40),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen(userType: widget.userType)));
                        },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.grey, fontSize: 15),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: "Sign Up",
                                style: TextStyle(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w400),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Required field' : null,
      ),
    );
  }
}