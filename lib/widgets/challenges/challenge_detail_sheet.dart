import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/core/challenge_models.dart';

// Bottom sheet that shows full challenge details and community submissions.
class ChallengeDetailSheet extends StatelessWidget {
  final DailyChallenge challenge;
  final bool adminViewEnabled;
  final VoidCallback? onEdit;

  const ChallengeDetailSheet({
    super.key,
    required this.challenge,
    this.adminViewEnabled = false,
    this.onEdit,
  });

  // Opens the detail sheet and returns `true` if the user chose to submit.
  static Future<bool> show(
    BuildContext context, {
    required DailyChallenge challenge,
    bool adminViewEnabled = false,
    VoidCallback? onEdit,
  }) async {
    var shouldSubmit = false;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ChallengeDetailBody(
          challenge: challenge,
          adminViewEnabled: adminViewEnabled,
          onEdit: onEdit,
          onSubmit: () {
            shouldSubmit = true;
            Navigator.of(sheetContext).pop(true);
          },
        );
      },
    );

    if (shouldSubmit && context.mounted) {
      context.push(
        Uri(
          path: '/post',
          queryParameters: {
            'challengeId': challenge.id,
            'challengeTitle': challenge.title,
            'challengeDescription': challenge.description,
          },
        ).toString(),
      );
    }

    return shouldSubmit;
  }

  @override
  Widget build(BuildContext context) {
    return _ChallengeDetailBody(
      challenge: challenge,
      adminViewEnabled: adminViewEnabled,
      onEdit: onEdit,
      onSubmit: () => Navigator.of(context).pop(true),
    );
  }
}

class _ChallengeDetailBody extends StatelessWidget {
  final DailyChallenge challenge;
  final bool adminViewEnabled;
  final VoidCallback? onEdit;
  final VoidCallback onSubmit;

  const _ChallengeDetailBody({
    required this.challenge,
    required this.adminViewEnabled,
    this.onEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: AppColors.prussianBlue,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero image
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: buildChallengeImage(
                      imagePath: challenge.imageUrl,
                      fit: BoxFit.cover,
                      iconName: challenge.iconName,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: ChallengeBadge(
                      label: relativeDateLabel(challenge.activationDate),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: CircleAvatar(
                      backgroundColor: AppColors.prussianBlue.withValues(
                        alpha: 0.75,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      challenge.description,
                      style: TextStyle(
                        color: AppColors.thistle,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Info pills
                    Row(
                      children: [
                        _InfoPill(
                          icon: Icons.schedule_rounded,
                          label: relativeDateLabel(challenge.activationDate),
                        ),
                        const SizedBox(width: 10),
                        _InfoPill(
                          icon: Icons.visibility_rounded,
                          label:
                              '${challenge.submissions.length} ${challenge.submissions.length == 1 ? 'submission' : 'submissions'}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.spaceIndigo.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.vintageLavender.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tips',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...challenge.tips.map(
                            (tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                    color: AppColors.honeyBronze,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: TextStyle(
                                        color: AppColors.thistle,
                                        height: 1.35,
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
                    const SizedBox(height: 18),

                    // Submissions header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Community Submissions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (challenge.submissions.length > 5)
                          TextButton(
                            onPressed: () =>
                                _showAllSubmissions(context, challenge),
                            child: Text(
                              'View All',
                              style: TextStyle(color: AppColors.honeyBronze),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Submissions list
                    if (challenge.submissions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.spaceIndigo.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'No submissions yet. Be the first to post your take on this challenge.',
                          style: TextStyle(color: AppColors.thistle),
                        ),
                      )
                    else
                      ...challenge.submissions
                          .take(5)
                          .map((s) => _SubmissionTile(submission: s)),

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: challenge.isCompleted ? null : onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.honeyBronze,
                              foregroundColor: AppColors.prussianBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: Icon(
                              challenge.isCompleted
                                  ? Icons.verified_rounded
                                  : Icons.camera_alt_rounded,
                            ),
                            label: Text(
                              challenge.isCompleted
                                  ? 'Completed'
                                  : 'Complete Now',
                            ),
                          ),
                        ),
                        if (adminViewEnabled && onEdit != null) ...[
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onEdit!();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.thistle,
                              side: BorderSide(
                                color: AppColors.vintageLavender.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit'),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllSubmissions(BuildContext context, DailyChallenge challenge) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: AppColors.prussianBlue,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'All Community Submissions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: AppColors.prussianBlue.withValues(
                            alpha: 0.75,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: challenge.submissions.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _SubmissionTile(
                          submission: challenge.submissions[index],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.vintageLavender.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.thistle),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.thistle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final ChallengeSubmission submission;
  const _SubmissionTile({required this.submission});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.spaceIndigo.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: submission.accentColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: buildChallengeImage(
                imagePath: submission.imageUrl,
                fit: BoxFit.cover,
                fallbackBuilder: () => Container(
                  color: AppColors.prussianBlue,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_rounded,
                    color: submission.accentColor,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      submission.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      submission.timeAgo,
                      style: TextStyle(
                        color: AppColors.thistle.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  submission.note,
                  style: TextStyle(color: AppColors.thistle, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
