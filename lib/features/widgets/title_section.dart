import 'package:flutter/material.dart';

class TitleSection extends StatelessWidget {
  const TitleSection({
    super.key, required this.title,  this.showSeeAll = true, this.onTap,
  });
  final String title;
  final bool showSeeAll;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if(showSeeAll)InkWell(
            onTap: (){
              onTap?.call();
            },
            child: Text("See All", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),))
      ],
    );
  }
}