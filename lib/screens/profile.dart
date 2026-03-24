import 'package:flutter/material.dart';
import 'package:astrophotography_blog/main.dart';
import 'package:astrophotography_blog/services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile',
              style: TextStyle(color: AppColors.thistle, fontSize: 24),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await AuthService().signOut();
              },
              child: const Text('Temporary Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
