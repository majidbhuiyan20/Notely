import 'package:flutter/material.dart';
import '../widgets/category_progress_list.dart';
import '../widgets/overall_progress_card.dart';
import '../widgets/profile_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // These would eventually come from Firebase
    const String userName = "Majid Bhuiyan";
    const String userEmail = "majid.bhuiyan@example.com";
    const String profileImageUrl = "https://picsum.photos/200";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const ProfileAppBar(
            name: userName,
            email: userEmail,
            imageUrl: profileImageUrl,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OverallProgressCard(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Category Progress"),
                  const SizedBox(height: 16),
                  const CategoryProgressList(),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E1E1E),
        letterSpacing: -0.5,
      ),
    );
  }
}
