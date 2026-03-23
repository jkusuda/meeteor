import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostCard({super.key, required this.post});

  Widget _buildActionButton(IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 0.5),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postUser = post['users'] as Map<String, dynamic>?;
    final username =
        postUser?['username'] as String? ??
        post['username'] as String? ??
        'unknown';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.spaceIndigo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.vintageLavender,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '@$username',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            child: post['imageUrl'] != null
                ? Image.network(
                    post['imageUrl'],
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.black45,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 50,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildActionButton(Icons.favorite_border),
                const SizedBox(width: 8),
                _buildActionButton(Icons.ios_share),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Text(
              post['caption'] ?? '',
              style: TextStyle(color: AppColors.thistle, fontSize: 14),
            ),
          ),
          Theme(
            data: ThemeData(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              minTileHeight: 36,
              title: Text(
                'Camera Settings',
                style: TextStyle(color: AppColors.honeyBronze, fontSize: 13),
              ),
              iconColor: AppColors.honeyBronze,
              collapsedIconColor: AppColors.honeyBronze,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Camera: ${post['camera'] ?? '-'}',
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'ISO: ${post['iso'] ?? '-'}',
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Aperture: ${post['aperture'] ?? '-'}',
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Exposure: ${post['exposure'] ?? '-'}',
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
