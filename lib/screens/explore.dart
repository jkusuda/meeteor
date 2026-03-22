import 'package:flutter/material.dart';
import 'package:astrophotography_blog/main.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      body: Center(
        child: Text(
          'Explore',
          style: TextStyle(color: AppColors.thistle, fontSize: 24),
        ),
      ),
    );
  }
}
