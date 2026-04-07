import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeteor/main.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Color? labelColor;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.spaceIndigo.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.vintageLavender.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.vintageLavender),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? AppColors.thistle,
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      value!,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.thistle.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.vintageLavender.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}
