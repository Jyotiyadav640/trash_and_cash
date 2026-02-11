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
      backgroundColor: const Color(0xFFF4F9F4), // Light greenish-white background
      body: Column(
        children: [
          // 1. Custom Modern Header
          _buildModernHeader(),

          // 2. Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Tab Switcher
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildTabButtons(),
                  ),
                  const SizedBox(height: 24),

                  // Leaderboard Stream
                  StreamBuilder<QuerySnapshot>(
                    stream: _leaderboardStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      final docs = snapshot.data!.docs;
                      final top3 = docs.take(3).toList();
                      final rest = docs.skip(3).toList();

                      return Column(
                        children: [
                          // 🏆 Top 3 Podium
                          if (top3.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildPodium(top3),
                            ),
                          
                          const SizedBox(height: 24),

                          // 📊 Your Rank Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildCurrentRankCard(docs),
                          ),
                          
                          const SizedBox(height: 24),

                          // 📜 Remaining List (Rank 4+)
                          if (rest.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      "Runner-ups",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),
                                  ...List.generate(rest.length, (index) {
                                    return _buildRankListItem(rest[index], index + 4);
                                  }),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 30),

                          // ⏳ Countdown
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildCountdownSection(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MODERN WIDGETS =================

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const Text(
            'Leaderboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildPodium(List<QueryDocumentSnapshot> docs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (docs.length > 1) _buildPodiumPlace(docs[1], 2), // 2nd Place
        if (docs.isNotEmpty) _buildPodiumPlace(docs[0], 1), // 1st Place
        if (docs.length > 2) _buildPodiumPlace(docs[2], 3), // 3rd Place
      ],
    );
  }

  Widget _buildPodiumPlace(QueryDocumentSnapshot doc, int rank) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'User';
    final points = _selectedTab == 0 ? (data['points'] ?? 0) : (data['totalPickups'] ?? 0);
    
    // Config for each rank
    final isFirst = rank == 1;
    final color = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    final height = rank == 1 ? 180.0 : (rank == 2 ? 140.0 : 120.0);
    final size = rank == 1 ? 80.0 : 60.0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Crown for 1st
          if (isFirst) 
             Padding(
               padding: const EdgeInsets.only(bottom: 8),
               child: Icon(Icons.emoji_events_rounded, color: color, size: 32),
             ),
          
          // Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: isFirst ? [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
              ] : null,
            ),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: color.withOpacity(0.1),
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            '$points pts',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
          ),
          
          const SizedBox(height: 12),

          // Platform
          Container(
            height: height * 0.4, // Reduced platform height
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankListItem(QueryDocumentSnapshot doc, int rank) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final data = doc.data() as Map<String, dynamic>;
    final isCurrentUser = doc.id == currentUid;
    final name = data['name'] ?? 'User';
    final points = _selectedTab == 0 ? (data['points'] ?? 0) : (data['totalPickups'] ?? 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.accent.withOpacity(0.05) : Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                color: isCurrentUser ? AppColors.accent : AppColors.text,
              ),
            ),
          ),
          Text(
            '$points',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRankCard(List<QueryDocumentSnapshot> docs) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    int? myRank;
    int myPoints = 0;

    for (int i = 0; i < docs.length; i++) {
        final data = docs[i].data() as Map<String, dynamic>;
        
        // ✨ LOGIC PRESERVED: Check for completedPickups > 0 for collectors, 
        // or just presence in filtered list for givers
        if (docs[i].id == uid) {
             // For display, get the correct points metric
             myPoints = _selectedTab == 0 ? (data['points'] ?? 0) : (data['totalPickups'] ?? 0);
             
             // The original logic checked completedPickups > 0 explicitly for ranking in some contexts,
             // but here the stream is already ordered. If you are in the top 20 list, you have a rank.
             // We'll maintain the index based rank.
             myRank = i + 1;
             break;
        }
    }

    if (myRank == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
               child: Icon(Icons.person, color: Color(0xFF1B5E20)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Current Rank',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  myRank != null ? '#$myRank' : 'Not Ranked',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$myPoints pts',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
     // 🚫 Giver/Collector simple user logic preserved
    if (widget.userType == 'giver' || widget.userType == 'collector') {
      return const SizedBox.shrink(); // Hide tabs if not admin/debugging
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Giver', Icons.eco_rounded, 0)),
          Expanded(child: _buildTabButton('Collector', Icons.local_shipping_rounded, 1)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.leaderboard_rounded, size: 60, color: Colors.grey[300]),
           const SizedBox(height: 16),
           Text(
             'No data available yet',
             style: TextStyle(color: Colors.grey[500]),
           ),
         ],
       ),
     );
  }

  Widget _buildCountdownSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            'SEASON ENDS IN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimerItem('$_daysLeft', 'DAYS'),
              _buildTimerSeparator(),
              _buildTimerItem('23', 'HRS'),
              _buildTimerSeparator(),
              _buildTimerItem('45', 'MIN'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimerItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400]),
        ),
      ],
    );
  }
  
  Widget _buildTimerSeparator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

}
