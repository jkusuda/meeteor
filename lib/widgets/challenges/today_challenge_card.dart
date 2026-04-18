import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/core/challenge_models.dart';

class TodayChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final String badgeLabel;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const TodayChallengeCard({
    super.key,
    required this.challenge,
    required this.badgeLabel,
    required this.icon,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.spaceIndigo.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.vintageLavender.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.45,
                      child: buildChallengeImage(
                        imagePath: challenge.imageUrl,
                        fit: BoxFit.cover,
                        iconName: challenge.iconName,
                        fallbackBuilder: () => Container(
                          color: AppColors.vintageLavender.withValues(
                            alpha: 0.2,
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, size: 72, color: AppColors.honeyBronze),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: ChallengeBadge(label: badgeLabel),
                  ),
                  if (onEdit != null)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.prussianBlue.withValues(
                          alpha: 0.75,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          color: Colors.white,
                          onPressed: onEdit,
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.vintageLavender.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.prussianBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  challenge.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFFB6A7D9),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            challenge.description,
                            style: TextStyle(
                              color: AppColors.thistle,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
