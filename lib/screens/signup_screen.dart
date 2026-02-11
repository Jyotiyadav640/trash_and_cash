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
  // --- Logic and Controllers remain exactly same ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _isPasswordVisible = false;

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
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = cred.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup failed: no user created.")),
        );
        setState(() => isLoading = false);
        return;
      }

      final uid = user.uid;
      final String collectionName =
          (widget.userType.toLowerCase() == 'giver') ? 'giverusers' : 'collectorusers';

      final Map<String, dynamic> payload = {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address, 
        'userType': widget.userType,
        'points': 0,
        'scanned': 0,
        'isFirstLogin': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection(collectionName).doc(uid).set(payload);

      try {
        await FirebaseAuth.instance.currentUser?.reload();
      } catch (_) {}

      if (!mounted) return;

      if (widget.userType.toLowerCase() == 'giver') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GiverHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CollectorHomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String msg = (e.code == 'email-already-in-use') ? "This email is already registered." : (e.code == 'weak-password' ? "Password should be at least 6 characters." : (e.code == 'invalid-email' ? "Please enter a valid email address." : e.message ?? "Signup failed."));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signup error: ${e.toString()}")));
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
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      body: Stack(
        children: [
          // Decorative background circle
          Positioned(
            top: -80,
            left: -80,
            child: CircleAvatar(radius: 120, backgroundColor: Colors.green.withOpacity(0.05)),
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
                    const SizedBox(height: 10),
                    const Text(
                      'Join Us!',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                    ),
                    Text(
                      'Register as a ${widget.userType} to start',
                      style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 30),

                    // Fields
                    _buildInputField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v!.isEmpty ? "Enter your name" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? "Enter email" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? "Enter phone number" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) => v!.isEmpty ? "Enter address" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      validator: (v) => v!.isEmpty ? "Enter password" : null,
                    ),

                    const SizedBox(height: 40),

                    // Signup Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 8,
                          shadowColor: Colors.green.withOpacity(0.3),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                            : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),

                    const SizedBox(height: 30),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.grey, fontSize: 15),
                            children: [
                              const TextSpan(text: "Already have an account? "),
                              TextSpan(
                                text: "Login Here",
                                style: TextStyle(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Modern Input Field
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
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
        maxLines: maxLines,
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
        validator: validator,
      ),
    );
  }
}