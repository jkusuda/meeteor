import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/screens/new_post.dart';

class ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final int columns;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.columns = 3,
  });

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'camera':
        return Icons.camera_alt;
      case 'moon':
        return Icons.nightlight_round;
      default:
        return Icons.extension;
    }
  }

  void _showChallengeDialog(
    BuildContext context,
    IconData icon,
    String name,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.spaceIndigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.honeyBronze),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          description,
          style: TextStyle(color: AppColors.thistle),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.honeyBronze,
                foregroundColor: AppColors.prussianBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NewPostPage(
                      challengeTitle: name,
                      challengeDescription: description,
                    ),
                  ),
                );
              },
              child: const Text('Complete Now'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconName = challenge['icon'] as String?;
    final title = challenge['title'] as String? ?? 'Challenge';
    final description = challenge['description'] as String? ?? '';
    final icon = _getIconData(iconName);

    final cardWidth =
      (MediaQuery.of(context).size.width - 32 - 16 - 36) / columns;
    return GestureDetector(
      onTap: () => _showChallengeDialog(context, icon, title, description),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        decoration: BoxDecoration(
          color: AppColors.vintageLavender.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 0.5),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.honeyBronze),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: AppColors.thistle),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
