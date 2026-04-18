import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/core/challenge_models.dart';
import 'package:meeteor/services/auth_service.dart';
import 'package:meeteor/services/challenge_service.dart';
import 'package:meeteor/screens/challenge_list_page.dart';
import 'package:meeteor/widgets/challenges/challenge_detail_sheet.dart';
import 'package:meeteor/widgets/challenges/challenge_editor_dialog.dart';
import 'package:meeteor/widgets/challenges/today_challenge_card.dart';
import 'package:meeteor/widgets/challenges/past_challenge_card.dart';
import 'package:meeteor/widgets/shimmer_loading.dart';
import 'package:meeteor/core/app_router.dart';

class ChallengesPage extends StatefulWidget {
  final bool adminViewEnabled;

  const ChallengesPage({super.key, this.adminViewEnabled = true});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final AuthService _authService = AuthService();
  final ChallengeService _challengeService = ChallengeService();

  List<DailyChallenge> _challenges = [];
  bool _isLoading = true;
  late bool _canUseAdminView;
  late bool _adminViewEnabled;

  @override
  void initState() {
    super.initState();
    _canUseAdminView = _authService.isAdmin;
    _adminViewEnabled = widget.adminViewEnabled && _canUseAdminView;
    _loadAdminState();
    _fetchChallenges();
    listRefreshNotifier.addListener(_onRefresh);
  }

  @override
  void dispose() {
    listRefreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    _fetchChallenges();
  }

  Future<void> _loadAdminState() async {
    final hasAccess = await _authService.hasAdminAccess();
    if (!mounted) return;
    setState(() {
      _canUseAdminView = hasAccess;
      _adminViewEnabled = widget.adminViewEnabled && hasAccess;
    });
  }

  Future<void> _fetchChallenges() async {
    if (_challenges.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final challenges = await _challengeService.fetchChallenges();
      if (!mounted) return;
      setState(() => _challenges = challenges);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load challenges.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const int _trophySlots = 7;

  DateTime get _todayDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int get _completedChallenges =>
      _challenges.where((c) => c.isCompleted).length;

  int get _trophiesEarned =>
      _completedChallenges > _trophySlots ? _trophySlots : _completedChallenges;

  DailyChallenge? get _todayChallenge {
    for (final challenge in _challenges) {
      if (normalizeDate(challenge.activationDate) == _todayDate) {
        return challenge;
      }
    }
    return null;
  }

  /// Returns challenges from the past 7 days.
  List<DailyChallenge> _recentChallenges({required bool past}) {
    final rangeEdge = past
        ? _todayDate.subtract(const Duration(days: 7))
        : _todayDate.add(const Duration(days: 7));

    final list = _challenges.where((c) {
      final d = normalizeDate(c.activationDate);
      if (past) {
        return d.isBefore(_todayDate) &&
            (d.isAfter(rangeEdge) || d.isAtSameMomentAs(rangeEdge));
      } else {
        return d.isAfter(_todayDate) &&
            (d.isBefore(rangeEdge) || d.isAtSameMomentAs(rangeEdge));
      }
    }).toList();

    if (!past) {
      list.sort((a, b) => a.activationDate.compareTo(b.activationDate));
    }
    return list;
  }

  List<DailyChallenge> _allChallenges({required bool past}) {
    final list = _challenges.where((c) {
      final d = normalizeDate(c.activationDate);
      return past ? d.isBefore(_todayDate) : d.isAfter(_todayDate);
    }).toList();

    if (!past) {
      list.sort((a, b) => a.activationDate.compareTo(b.activationDate));
    }
    return list;
  }

  // Actions

  Future<void> _openChallengeDetails(DailyChallenge challenge) async {
    await ChallengeDetailSheet.show(
      context,
      challenge: challenge,
      adminViewEnabled: _adminViewEnabled,
      onEdit: () => _openEditor(challenge: challenge),
    );
  }

  Future<void> _openEditor({DailyChallenge? challenge}) async {
    final message = await ChallengeEditorDialog.show(
      context,
      challenge: challenge,
      challengeService: _challengeService,
      onSaved: _fetchChallenges,
    );

    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/starry_sky_bg_1.png', fit: BoxFit.cover),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _GlowBlob(
              color: AppColors.honeyBronze.withValues(alpha: 0.18),
              size: 220,
            ),
          ),
          Positioned(
            bottom: 120,
            left: -120,
            child: _GlowBlob(
              color: AppColors.vintageLavender.withValues(alpha: 0.16),
              size: 260,
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: ChallengeSkeleton(),
              ),
            ),
          if (!_isLoading)
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 72),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildHeader(),
                        const SizedBox(height: 22),
                        _buildTrophyCollection(),
                        if (_adminViewEnabled) ...[
                          const SizedBox(height: 18),
                          _buildAdminTools(),
                        ],
                        const SizedBox(height: 22),
                        _buildTodaySection(),
                        const SizedBox(height: 22),
                        _buildChallengeListSection(
                          title: 'Past Challenges',
                          emptyMessage: 'No past challenges to view.',
                          viewAllTitle: 'Past Challenges',
                          viewAllEmptyMessage: 'No past challenges available.',
                          past: true,
                        ),
                        if (_adminViewEnabled) ...[
                          const SizedBox(height: 22),
                          _buildChallengeListSection(
                            title: 'Future Challenges',
                            emptyMessage:
                                'No upcoming challenges in the next 7 days.',
                            viewAllTitle: 'Upcoming Challenges',
                            viewAllEmptyMessage:
                                'No upcoming challenges scheduled.',
                            past: false,
                            showEditButton: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Challenges',
          style: TextStyle(
            color: AppColors.thistle,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Complete challenges to earn trophies and gain experience capturing the cosmos.',
          style: TextStyle(
            color: AppColors.vintageLavender,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildTrophyCollection() {
    final trophiesEarned = _trophiesEarned;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.spaceIndigo.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.vintageLavender.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Trophy Collection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.emoji_events_rounded, color: AppColors.honeyBronze),
              const SizedBox(width: 6),
              Text(
                '$trophiesEarned',
                style: TextStyle(
                  color: AppColors.honeyBronze,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final trophySize =
                  ((availableWidth - ((_trophySlots - 1) * 8)) / _trophySlots)
                      .clamp(32.0, 50.0);
              final iconSize = trophySize * 0.6;

              return Row(
                children: List.generate(_trophySlots, (index) {
                  final earned = index < trophiesEarned;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < _trophySlots - 1 ? 8 : 0,
                    ),
                    child: Container(
                      width: trophySize,
                      height: trophySize,
                      decoration: BoxDecoration(
                        color: earned
                            ? AppColors.honeyBronze.withValues(alpha: 0.95)
                            : AppColors.spaceIndigo.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(trophySize * 0.36),
                        border: Border.all(
                          color: earned
                              ? AppColors.honeyBronze
                              : AppColors.vintageLavender.withValues(
                                  alpha: 0.28,
                                ),
                        ),
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: iconSize,
                        color: earned
                            ? AppColors.prussianBlue
                            : AppColors.vintageLavender,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Keep up with the daily challenges this week! $trophiesEarned/$_trophySlots trophies collected.',
            style: TextStyle(
              color: AppColors.thistle,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTools() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.honeyBronze.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.honeyBronze.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.honeyBronze,
              ),
              const SizedBox(width: 10),
              const Text(
                'Admin Challenge Tools',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Create a new challenge or edit the current prompt for today.',
            style: TextStyle(color: AppColors.thistle, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Create Challenge'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.honeyBronze,
                foregroundColor: AppColors.prussianBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Challenge",
          style: TextStyle(
            color: AppColors.thistle,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (_challenges.isEmpty)
          _emptyBox('No daily challenges yet.')
        else if (_todayChallenge == null)
          _emptyBox('No challenge is scheduled for today.')
        else
          TodayChallengeCard(
            challenge: _todayChallenge!,
            badgeLabel: relativeDateLabel(_todayChallenge!.activationDate),
            icon: iconForName(_todayChallenge!.iconName),
            onTap: () => _openChallengeDetails(_todayChallenge!),
            onEdit: _adminViewEnabled
                ? () => _openEditor(challenge: _todayChallenge!)
                : null,
          ),
      ],
    );
  }

  /// Builds either the "Past Challenges" or "Future Challenges" section.
  Widget _buildChallengeListSection({
    required String title,
    required String emptyMessage,
    required String viewAllTitle,
    required String viewAllEmptyMessage,
    required bool past,
    bool showEditButton = false,
  }) {
    final recent = _recentChallenges(past: past);
    final all = _allChallenges(past: past);
    final hasMore = all.length > recent.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.thistle,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasMore)
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChallengeListPage(
                        title: viewAllTitle,
                        emptyMessage: viewAllEmptyMessage,
                        challenges: all,
                        onChallengeSelected: _openChallengeDetails,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.honeyBronze,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Text(emptyMessage, style: TextStyle(color: AppColors.thistle))
        else
          ...recent.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PastChallengeCard(
                challenge: entry.value,
                dateLabel: relativeDateLabel(entry.value.activationDate),
                icon: iconForName(entry.value.iconName),
                accent: highlightForIndex(entry.key),
                onTap: () => _openChallengeDetails(entry.value),
                onEdit: (_adminViewEnabled || showEditButton)
                    ? () => _openEditor(challenge: entry.value)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.spaceIndigo.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.vintageLavender.withValues(alpha: 0.3),
        ),
      ),
      child: Text(message, style: TextStyle(color: AppColors.thistle)),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
