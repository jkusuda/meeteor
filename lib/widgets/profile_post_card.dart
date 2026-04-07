import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/screens/post_detail.dart';

class ProfilePostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const ProfilePostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (post['image_url'] ?? post['imageUrl']) as String?;
    final postId = post['id']?.toString() ?? 'demo_id';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(postId: postId),
          ),
        );
      },
      child: ClipRRect(
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
          ],
        ),
      ),
    );
  }
}
