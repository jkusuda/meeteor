import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/core/challenge_models.dart';

class PastChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final String dateLabel;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const PastChallengeCard({
    super.key,
    required this.challenge,
    required this.dateLabel,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.spaceIndigo.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.prussianBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (challenge.isCompleted)
                Icon(Icons.check_circle_rounded, size: 18, color: accent),
              if (challenge.isCompleted) const SizedBox(width: 8),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  color: AppColors.thistle,
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.vintageLavender,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
