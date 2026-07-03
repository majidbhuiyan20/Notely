import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CategoryModel {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  const CategoryModel({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });

  static const List<CategoryModel> all = [
    CategoryModel(title: 'All Notes', icon: Icons.note_alt_outlined, color: AppColors.royalBlue, count: 45),
    CategoryModel(title: 'Personal', icon: Icons.person_outline, color: AppColors.green, count: 12),
    CategoryModel(title: 'Work', icon: Icons.work_outline, color: AppColors.orange, count: 8),
    CategoryModel(title: 'Health', icon: Icons.favorite_border, color: AppColors.red, count: 5),
    CategoryModel(title: 'Finance', icon: Icons.account_balance_wallet_outlined, color: AppColors.teal, count: 3),
    CategoryModel(title: 'Travel', icon: Icons.flight_takeoff, color: AppColors.cyan, count: 7),
    CategoryModel(title: 'Shopping', icon: Icons.shopping_cart_outlined, color: AppColors.pink, count: 10),
    CategoryModel(title: 'Food', icon: Icons.restaurant, color: AppColors.coral, count: 4),
    CategoryModel(title: 'Ideas', icon: Icons.lightbulb_outline, color: AppColors.purple, count: 15),
    CategoryModel(title: 'Music', icon: Icons.music_note, color: AppColors.indigo, count: 6),
    CategoryModel(title: 'Sports', icon: Icons.sports_basketball, color: AppColors.crimson, count: 2),
    CategoryModel(title: 'Education', icon: Icons.school_outlined, color: AppColors.violet, count: 9),
    CategoryModel(title: 'Photography', icon: Icons.camera_alt_outlined, color: AppColors.turquoise, count: 11),
    CategoryModel(title: 'Coding', icon: Icons.code, color: AppColors.blue, count: 20),
    CategoryModel(title: 'Art', icon: Icons.palette_outlined, color: AppColors.magenta, count: 5),
    CategoryModel(title: 'Gardening', icon: Icons.local_florist_outlined, color: AppColors.lime, count: 3),
    CategoryModel(title: 'Gaming', icon: Icons.sports_esports_outlined, color: AppColors.brown, count: 8),
    CategoryModel(title: 'Movies', icon: Icons.movie_filter_outlined, color: AppColors.gold, count: 12),
    CategoryModel(title: 'Books', icon: Icons.menu_book_outlined, color: AppColors.orange, count: 14),
    CategoryModel(title: 'Weather', icon: Icons.wb_sunny_outlined, color: AppColors.mint, count: 1),
    CategoryModel(title: 'Others', icon: Icons.more_horiz_outlined, color: AppColors.grey, count: 2),
  ];
}
