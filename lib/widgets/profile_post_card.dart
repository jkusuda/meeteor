import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeteor/main.dart';

class ProfilePostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const ProfilePostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final imageUrl = post['imageUrl'] as String?;
    final caption = post['caption'] as String? ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image (or placeholder)
          imageUrl != null
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Container(
                  color: AppColors.spaceIndigo,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: AppColors.vintageLavender,
                    size: 32,
                  ),
                ),

          // Gradient overlay + caption at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.thistle,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
