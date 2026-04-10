import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const ProfilePostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final imageUrl = post['imageUrl'] ?? post['image_url'];

    return GestureDetector(
      onTap: () {
        context.push('/p/${post['id']}');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : Container(
                color: Colors.black45,
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
      ),
    );
  }
}
