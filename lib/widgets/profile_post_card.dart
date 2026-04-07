import 'package:flutter/material.dart';
import 'package:meeteor/widgets/post_card.dart';

class ProfilePostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const ProfilePostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: PostCard(post: post),
    );
  }
}
