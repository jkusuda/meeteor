import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeteor/main.dart';

class AvatarPopup extends StatelessWidget {
  final Future<void> Function(String) onIconSelected;
  final String? currentIcon;

  static const List<String> _spaceIcons = [
    '👨‍🚀',
    '👩‍🚀',
    '🪐',
    '🚀',
    '🛰️',
    '☄️',
    '🌕',
    '✨',
    '🌙',
    '☀️',
    '🛸',
    '👽',
  ];

  const AvatarPopup({
    super.key,
    required this.onIconSelected,
    this.currentIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        color: AppColors.spaceIndigo,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.vintageLavender.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Select Your Avatar',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.thistle,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _spaceIcons.length,
            itemBuilder: (context, index) {
              final icon = _spaceIcons[index];
              final isSelected = currentIcon == icon;
              return GestureDetector(
                onTap: () async {
                  Navigator.of(context).pop();
                  await onIconSelected(icon);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.honeyBronze.withValues(alpha: 0.2)
                        : AppColors.prussianBlue.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.honeyBronze
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 32)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

Future<void> showAvatarPopup({
  required BuildContext context,
  required String? currentIcon,
  required Future<void> Function(String) onIconSelected,
}) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => AvatarPopup(
      currentIcon: currentIcon,
      onIconSelected: onIconSelected,
    ),
  );
}
