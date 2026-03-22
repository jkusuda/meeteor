import 'package:flutter/material.dart';
import 'package:astrophotography_blog/main.dart';

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      body: Center(
        child: Text(
          'Challenges',
          style: TextStyle(color: AppColors.thistle, fontSize: 24),
        ),
      ),
    );
  }
}
