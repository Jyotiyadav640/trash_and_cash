import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LeaderboardScreen extends StatefulWidget {
  final String userType; // 👈 NEW
  // 👈 NEW
  const LeaderboardScreen({super.key, required this.userType});
  


  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}


class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0; // 0 = Giver, 1 = Collector
  
  final int _daysLeft = 6;

  // ✅ YAHI PE PASTE KARO
  Stream<QuerySnapshot> _leaderboardStream() {
    if (_selectedTab == 0) {
      return FirebaseFirestore.instance
          .collection('giverusers')
          .orderBy('points', descending: true)
          .limit(20)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('collectorusers')
          .orderBy('totalPickups', descending: true)
          .limit(20)
          .snapshots();
    }
  }

  @override
void initState() {
  super.initState();

  if (widget.userType == 'collector') {
    _selectedTab = 1;
  } else {
    _selectedTab = 0;//giver+admin dono ke liye 0 hi rhega
  }
}




  

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

// ✅ APP BAR WITH BACK BUTTON
    appBar: AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.text),
        onPressed: () {
          Navigator.pop(context); // 👈 BACK to previous screen
        },
      ),
      title: const Text(
        'Leaderboard',
        style: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    ),

    // ✅ BODY (tumhara purana content same)





      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // Header
            const Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 20),
            
            // Current League Badge
          
            
            // Tab Buttons
            _buildTabButtons(),
            const SizedBox(height: 20),
            
            // Leaderboard List
            _buildLeaderboardList(),
            const SizedBox(height: 20),
            
            // Promotion Info
            _buildPromotionInfo(),
            const SizedBox(height: 20),
            
            // Countdown Timer
            _buildCountdownSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }


 Widget _buildLeagueBadge(int? myRank) {
  return Center(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent),
      ),
      child: Column(
        children: [
          const Text(
            'Current League',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gold League',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    myRank != null
                        ? 'Your Rank: #$myRank'
                        : 'Your Rank: --',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


  Widget _buildTabButtons() {
  // 🚫 Giver login → tabs mat dikhao
  if (widget.userType == 'giver') {
    return const SizedBox.shrink();
  }

  // 🚫 Collector login → tabs mat dikhao
  if (widget.userType == 'collector') {
    return const SizedBox.shrink();
  }

  // ✅ Future use (admin / combined)
  return Container(
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    padding: const EdgeInsets.all(4),
    child: Row(
      children: [
        Expanded(
          child: _buildTabButton(
            label: 'Giver',
            icon: Icons.person_add,
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTabButton(
            label: 'Collector',
            icon: Icons.local_shipping,
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textLight,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildLeaderboardList() {
  final currentUid = FirebaseAuth.instance.currentUser!.uid;

  return StreamBuilder<QuerySnapshot>(
    stream: _leaderboardStream(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final docs = snapshot.data!.docs;
      int? myRank;

      // 🔥 current user ka rank nikal rahe hain
      for (int i = 0; i < docs.length; i++) {
        if (docs[i].id == currentUid) {
          myRank = i + 1;
          break;
        }
      }

      return Column(
        children: [
          // ✅ SAME leaderboard position = SAME rank
          _buildLeagueBadge(myRank),

          const SizedBox(height: 20),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final rank = index + 1;
              final isCurrentUser = docs[index].id == currentUid;

              final name = data['name'] ?? 'User';
              final points = _selectedTab == 0
                  ? data['points'] ?? 0
                  : data['totalPickups'] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? AppColors.accent.withOpacity(0.1)
                      : AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrentUser
                        ? AppColors.accent
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    // RANK
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser
                              ? AppColors.accent
                              : AppColors.text,
                        ),
                      ),
                    ),

                    Text(
                      points.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    },
  );
}


  Widget _buildPromotionInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_upward, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Top 3 Get Promoted',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '🥇 Gold League  🥈 Silver League  🥉 Bronze League',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.text,
              height: 1.6,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Top 3 performers from Bronze & Silver will be promoted to the next league.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Next Season In',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCountdownCard('$_daysLeft', 'Days'),
              const SizedBox(width: 12),
              _buildCountdownCard('23', 'Hours'),
              const SizedBox(width: 12),
              _buildCountdownCard('45', 'Minutes'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Leaderboard refreshes weekly on Monday',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
