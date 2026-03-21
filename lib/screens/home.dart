// home screen code
import 'package:flutter/material.dart';
import 'package:astrophotography_blog/services/auth_service.dart';
import 'package:astrophotography_blog/main.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildChallengeCard(
    BuildContext context,
    IconData icon,
    String name,
    String description,
  ) {
    final cardWidth = (MediaQuery.of(context).size.width - 32 - 16 - 36) / 3;
    return GestureDetector(
      onTap: () => _showChallengeDialog(context, icon, name, description),
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
              name,
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

  void _showChallengeDialog(
    BuildContext context,
    IconData icon,
    String name,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.spaceIndigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.honeyBronze),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          description,
          style: TextStyle(color: AppColors.thistle),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.honeyBronze,
                foregroundColor: AppColors.prussianBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Complete Now'),
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, String>> posts = const [
    {
      'username': 'astro_jane',
      'caption': 'Orion Nebula on a clear winter night',
      'imageUrl': 'https://picsum.photos/seed/orion/800/600',
      'iso': '3200',
      'aperture': 'f/2.8',
      'exposure': '30s',
      'camera': 'Canon EOS Ra',
    },
    {
      'username': 'stargazer_mike',
      'caption': 'Milky Way rising over the desert',
      'imageUrl': 'https://picsum.photos/seed/milkyway/800/600',
      'iso': '6400',
      'aperture': 'f/1.8',
      'exposure': '20s',
      'camera': 'Sony A7III',
    },
  ];

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

  Widget _buildPostCard(Map<String, String> post) {
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
                    post['username']![0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '@${post['username']}',
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
            child: Image.network(
              post['imageUrl']!,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
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
              post['caption']!,
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
                          'Camera: ${post['camera']}',
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'ISO: ${post['iso']}',
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Aperture: ${post['aperture']}',
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Exposure: ${post['exposure']}',
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

  Widget _buildPostFeed() {
    if (posts.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Icon(Icons.nightlight_round, size: 48, color: AppColors.honeyBronze),
          const SizedBox(height: 16),
          Text(
            'no new posts,\ncurrently mesmerized by the moon',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.thistle),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(posts[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 1.0,
              child: Image.asset(
                'assets/starry_sky_bg_1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
                    child: Text(
                      'welcome back\nto the stars',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cedarvilleCursive(
                        fontSize: 28,
                        color: AppColors.honeyBronze,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 14),
                          padding: const EdgeInsets.only(top: 16, bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.vintageLavender,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SizedBox(
                            height: 150,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              children: [
                                _buildChallengeCard(
                                  context,
                                  Icons.star,
                                  'First Light',
                                  'Capture your first photo of the night sky',
                                ),
                                _buildChallengeCard(
                                  context,
                                  Icons.camera_alt,
                                  'Long Exposure',
                                  'Take a 30+ second exposure of the Milky Way',
                                ),
                                _buildChallengeCard(
                                  context,
                                  Icons.nightlight_round,
                                  'Lunar Detail',
                                  'Photograph craters on the Moon\'s surface',
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 16,
                          child: IntrinsicWidth(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 14,
                                  child: Container(
                                    height: 2,
                                    color: AppColors.prussianBlue,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'Daily Challenges',
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.thistle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (posts.isEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 32),
                        Icon(
                          Icons.nightlight_round,
                          size: 48,
                          color: AppColors.honeyBronze,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no new posts,\ncurrently mesmerized by the moon',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.thistle,
                          ),
                        ),
                      ],
                    )
                  else
                    ...posts.map((post) => _buildPostCard(post)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
