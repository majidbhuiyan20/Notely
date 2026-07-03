import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/route/app_route.dart';

class NoteList extends StatelessWidget {
  const NoteList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              Navigator.pushNamed(context, Routes.taskRoute);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.royalBlue.withOpacity(0.1), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: AppColors.royalBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.royalBlue.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                              ),
                              child: const Icon(Icons.person_outline, color: AppColors.royalBlue, size: 28),
                            )
                          ]
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Product RoadMap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("2h Ago", style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),)
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.royalBlue.withOpacity(0.2), width: 1),
                      ),
                      child: const Text("Personal", style: TextStyle(fontSize: 14, color: AppColors.royalBlue, fontWeight: FontWeight.w500), ),
                    )
                  ],
                )
            ),
          );
        }
    );
  }
}
