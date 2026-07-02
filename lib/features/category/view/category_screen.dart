import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/category_card.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final List<Map<String, dynamic>> categories = [
    {'title': 'All Notes', 'icon': Icons.note_alt_outlined, 'color': AppColors.royalBlue, 'count': 45},
    {'title': 'Personal', 'icon': Icons.person_outline, 'color': AppColors.green, 'count': 12},
    {'title': 'Work', 'icon': Icons.work_outline, 'color': AppColors.orange, 'count': 8},
    {'title': 'Health', 'icon': Icons.favorite_border, 'color': AppColors.red, 'count': 5},
    {'title': 'Finance', 'icon': Icons.account_balance_wallet_outlined, 'color': AppColors.teal, 'count': 3},
    {'title': 'Travel', 'icon': Icons.flight_takeoff, 'color': AppColors.cyan, 'count': 7},
    {'title': 'Shopping', 'icon': Icons.shopping_cart_outlined, 'color': AppColors.pink, 'count': 10},
    {'title': 'Food', 'icon': Icons.restaurant, 'color': AppColors.coral, 'count': 4},
    {'title': 'Ideas', 'icon': Icons.lightbulb_outline, 'color': AppColors.purple, 'count': 15},
    {'title': 'Music', 'icon': Icons.music_note, 'color': AppColors.indigo, 'count': 6},
    {'title': 'Sports', 'icon': Icons.sports_basketball, 'color': AppColors.crimson, 'count': 2},
    {'title': 'Education', 'icon': Icons.school_outlined, 'color': AppColors.violet, 'count': 9},
    {'title': 'Photography', 'icon': Icons.camera_alt_outlined, 'color': AppColors.turquoise, 'count': 11},
    {'title': 'Coding', 'icon': Icons.code, 'color': AppColors.blue, 'count': 20},
    {'title': 'Art', 'icon': Icons.palette_outlined, 'color': AppColors.magenta, 'count': 5},
    {'title': 'Gardening', 'icon': Icons.local_florist_outlined, 'color': AppColors.lime, 'count': 3},
    {'title': 'Gaming', 'icon': Icons.sports_esports_outlined, 'color': AppColors.brown, 'count': 8},
    {'title': 'Movies', 'icon': Icons.movie_filter_outlined, 'color': AppColors.gold, 'count': 12},
    {'title': 'Books', 'icon': Icons.menu_book_outlined, 'color': AppColors.orange, 'count': 14},
    {'title': 'Weather', 'icon': Icons.wb_sunny_outlined, 'color': AppColors.mint, 'count': 1},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Categories',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 16),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Manage your thoughts".toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.royalBlue.withOpacity(0.8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "All Categories",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E1E),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = categories[index];
                  return CategoryCard(
                    title: category['title'],
                    icon: category['icon'],
                    color: category['color'],
                    count: category['count'],
                    onTap: () {
                      // Navigate to category details
                    },
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
