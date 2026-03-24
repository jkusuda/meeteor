import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  final bool isDemoMode;
  final VoidCallback? onToggleDemo;

  const ProfilePage({
    super.key,
    this.isDemoMode = true,
    this.onToggleDemo,
  });

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
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 16),
            if (onToggleDemo != null)
              ElevatedButton(
                onPressed: onToggleDemo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDemoMode ? AppColors.honeyBronze : AppColors.spaceIndigo,
                  foregroundColor: isDemoMode ? AppColors.prussianBlue : Colors.white,
                ),
                child: Text(isDemoMode ? 'Using Demo Data - Switch Live' : 'Using Live Data - Switch Demo'),
              ),
          ],
        ),
      ),
    );
  }
}
