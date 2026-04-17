import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/screens/challenges.dart';

class AllPastChallengesPage extends StatefulWidget {
  final List<DailyChallenge> challenges;
  final Function(DailyChallenge) onChallengeSelected;
  final Function(DateTime) relativeDateLabel;
  final Function(String) iconForName;

  const AllPastChallengesPage({
    super.key,
    required this.challenges,
    required this.onChallengeSelected,
    required this.relativeDateLabel,
    required this.iconForName,
  });

  @override
  State<AllPastChallengesPage> createState() => _AllPastChallengesPageState();
}

class _AllPastChallengesPageState extends State<AllPastChallengesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.honeyBronze, width: 1.5),
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.honeyBronze,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Past Challenges',
          style: TextStyle(
            color: AppColors.thistle,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/starry_sky_bg_1.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.challenges.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48.0),
                        child: Text(
                          'No past challenges available.',
                          style: TextStyle(color: AppColors.thistle),
                        ),
                      ),
                    )
                  else
                    ...widget.challenges.map(
                      (challenge) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PastChallengeWithImageCard(
                          challenge: challenge,
                          dateLabel: widget.relativeDateLabel(
                            challenge.activationDate,
                          ),
                          onTap: () => widget.onChallengeSelected(challenge),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PastChallengeWithImageCard extends StatelessWidget {
  final DailyChallenge challenge;
  final String dateLabel;
  final VoidCallback onTap;

  const _PastChallengeWithImageCard({
    required this.challenge,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: _buildChallengeImage(
                    challenge.imageUrl,
                    BoxFit.cover,
                    challenge.iconName,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.honeyBronze,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        color: AppColors.prussianBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              color: AppColors.spaceIndigo,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    challenge.description,
                    style: TextStyle(
                      color: AppColors.thistle,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeImage(String imagePath, BoxFit fit, String iconName) {
    if (imagePath.isEmpty ||
        imagePath ==
            'https://images.unsplash.com/photo-1464802686167-b939a6910659?auto=format&fit=crop&w=1200&q=80') {
      return Container(
        color: AppColors.spaceIndigo,
        alignment: Alignment.center,
        child: Icon(
          _iconForName(iconName),
          size: 72,
          color: AppColors.honeyBronze,
        ),
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.spaceIndigo,
          alignment: Alignment.center,
          child: Icon(
            _iconForName(iconName),
            size: 72,
            color: AppColors.honeyBronze,
          ),
        ),
      );
    }

    return Image.network(
      imagePath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.spaceIndigo,
        alignment: Alignment.center,
        child: Icon(
          _iconForName(iconName),
          size: 72,
          color: AppColors.honeyBronze,
        ),
      ),
    );
  }

  IconData _iconForName(String iconName) {
    switch (iconName) {
      case 'camera':
        return Icons.camera_alt_rounded;
      case 'moon':
        return Icons.nightlight_round_rounded;
      case 'star':
      default:
        return Icons.star_rounded;
    }
  }
}
