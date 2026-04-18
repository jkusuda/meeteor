import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/core/challenge_models.dart';

// Compact challenge card used in the horizontal list on the home page.
class ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final int columns;

  const ChallengeCard({super.key, required this.challenge, this.columns = 3});

  void _showChallengeDialog(
    BuildContext context,
    IconData icon,
    String name,
    String description,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.spaceIndigo,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.prussianBlue,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(icon, size: 48, color: AppColors.honeyBronze),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(color: AppColors.thistle),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.honeyBronze,
                        foregroundColor: AppColors.prussianBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.push(
                          Uri(
                            path: '/post',
                            queryParameters: {
                              'challengeTitle': name,
                              'challengeDescription': description,
                            },
                          ).toString(),
                        );
                      },
                      child: const Text('Complete Now'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconName =
        (challenge['icon'] ?? challenge['icon_name'] ?? 'star') as String;
    final title = challenge['title'] as String? ?? 'Challenge';
    final description = challenge['description'] as String? ?? '';
    final icon = iconForName(iconName);

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
