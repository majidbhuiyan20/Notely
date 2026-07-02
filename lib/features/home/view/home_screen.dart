import 'package:flutter/material.dart';
import 'package:notely/core/route/app_route.dart';

import '../../widgets/category_card.dart';
import '../../widgets/note_list.dart';
import '../../widgets/search_field.dart';
import '../../widgets/title_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hi, Majid Bhuiyan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            Text("Good Morning", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://picsum.photos/200'),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding:  EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const Text(
                  //   "What's on your mind today?",
                  //   style: TextStyle(fontSize: 16, color: Colors.black87),
                  // ),
                  SearchField(),
        
                  const SizedBox(height: 12),
                  TitleSection(title: 'Categories',onTap: (){
                    Navigator.pushNamed(context, Routes.categoryRoute);
                  },),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        CategoryCard(
                          icon: Icons.note_alt_outlined,
                          title: "All Notes",
                          count: 24,
                          color: Colors.blue,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        CategoryCard(
                          icon: Icons.person_outline,
                          title: "Personal",
                          count: 10,
                          color: Colors.green,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        CategoryCard(
                          icon: Icons.work_outline,
                          title: "Work",
                          count: 12,
                          color: Colors.orange,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        CategoryCard(
                          icon: Icons.lightbulb_outline,
                          title: "Ideas",
                          count: 5,
                          color: Colors.purple,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TitleSection(title: 'Pined Note'),
                  const SizedBox(height: 12),
                  NoteList(),
                  const SizedBox(height: 12),
                  TitleSection(title: 'All Notes'),
                  const SizedBox(height: 12),
                  NoteList(),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}




