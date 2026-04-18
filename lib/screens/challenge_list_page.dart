import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/core/challenge_models.dart';

class ChallengeListPage extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<DailyChallenge> challenges;
  final Function(DailyChallenge) onChallengeSelected;

  const ChallengeListPage({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.challenges,
    required this.onChallengeSelected,
  });

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
          title,
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
                  if (challenges.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48.0),
                        child: Text(
                          emptyMessage,
                          style: TextStyle(color: AppColors.thistle),
                        ),
                      ),
                    )
                  else
                    ...challenges.map(
                      (challenge) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ChallengeImageCard(
                          challenge: challenge,
                          dateLabel: relativeDateLabel(
                            challenge.activationDate,
                          ),
                          onTap: () => onChallengeSelected(challenge),
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

class ChallengeImageCard extends StatelessWidget {
  final DailyChallenge challenge;
  final String dateLabel;
  final VoidCallback onTap;

  const ChallengeImageCard({
    super.key,
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
                  child: buildChallengeImage(
                    imagePath: challenge.imageUrl,
                    fit: BoxFit.cover,
                    iconName: challenge.iconName,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: ChallengeBadge(label: dateLabel, fontSize: 12),
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
}
