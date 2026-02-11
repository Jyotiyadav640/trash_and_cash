import 'package:flutter/material.dart';
import 'login_screen.dart';

class UserTypeScreen extends StatefulWidget {
  const UserTypeScreen({super.key});

  @override
  State<UserTypeScreen> createState() => _UserTypeScreenState();
}

class _UserTypeScreenState extends State<UserTypeScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8), // Off-white for premium feel
      body: Stack( // Background elements ke liye Stack use kiya hai
        children: [
          // Background Decorative Circles (Ye screen ko "bhar" denge)
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(radius: 100, backgroundColor: Colors.green.withOpacity(0.05)),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: CircleAvatar(radius: 80, backgroundColor: Colors.blue.withOpacity(0.05)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  // Top Header with a small Icon to fill space
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Your Role',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B5E20),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'How would you like to help?',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      // Chota sa logo/icon top right mein
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.eco_rounded, color: Colors.green, size: 30),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Roles Section
                  _buildRoleCard(
                    title: 'Give Trash',
                    description: 'Donate or sell your recyclables and get rewarded.',
                    imageUrl: "https://cdn-icons-png.flaticon.com/512/3050/3050013.png", 
                    accentColor: const Color(0xFF4CAF50),
                    role: 'giver',
                  ),

                  const SizedBox(height: 24),

                  _buildRoleCard(
                    title: 'Collect Trash',
                    description: 'Earn points by picking up and managing waste.',
                    imageUrl: "https://cdn-icons-png.flaticon.com/512/2853/2853835.png",
                    accentColor: const Color(0xFF2196F3),
                    role: 'collector',
                  ),

                  const Spacer(flex: 2),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _selectedRole == null 
                        ? null 
                        : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(userType: _selectedRole!),
                            ),
                          );
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: _selectedRole != null ? 8 : 0,
                        shadowColor: Colors.green.withOpacity(0.4),
                      ),
                      child: Text(
                        _selectedRole == null ? 'Please Select a Role' : 'Continue',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required String imageUrl,
    required Color accentColor,
    required String role,
  }) {
    bool isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // Card hamesha white rahega taaki khali na lage
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey[200]!,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? accentColor.withOpacity(0.15) 
                : Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.1) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? accentColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.3),
                  ),
                ],
              ),
            ),
            // Custom Radio Icon
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? accentColor : Colors.grey[300],
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}