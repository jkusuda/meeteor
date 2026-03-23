// home screen code
import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:meeteor/widgets/challenge_card.dart';
import 'package:meeteor/widgets/post_card.dart';

class HomePage extends StatefulWidget {
  final bool isDemoMode;

  const HomePage({super.key, this.isDemoMode = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _livePosts = [];
  List<Map<String, dynamic>> _liveChallenges = [];
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchSupabaseData();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDemoMode != oldWidget.isDemoMode && !widget.isDemoMode) {
      _fetchSupabaseData();
    }
  }

  Future<void> _fetchSupabaseData() async {
    if (widget.isDemoMode) return;

    setState(() => _isLoading = true);
    try {
      final session = Supabase.instance.client.auth.currentSession;

      final futures = <Future>[
        Supabase.instance.client
            .from('posts')
            .select('*, users(username, avatar_id)')
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('challenges')
            .select()
            .order('created_at', ascending: false),
      ];

      if (session != null) {
        futures.add(
          Supabase.instance.client
              .from('users')
              .select('username')
              .eq('id', session.user.id)
              .maybeSingle(),
        );
      }

      final results = await Future.wait(futures);

      _livePosts = List<Map<String, dynamic>>.from(results[0]);
      _liveChallenges = List<Map<String, dynamic>>.from(results[1]);

      if (session != null && results.length > 2) {
        final userData = results[2];
        if (userData != null) {
          _username = userData['username'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final List<Map<String, dynamic>> demoChallenges = const [
    {
      'icon': 'star',
      'title': 'First Light',
      'description': 'Capture your first photo of the night sky',
    },
    {
      'icon': 'camera',
      'title': 'Long Exposure',
      'description': 'Take a 30+ second exposure of the Milky Way',
    },
    {
      'icon': 'moon',
      'title': 'Lunar Detail',
      'description': 'Photograph craters on the Moon\'s surface',
    },
  ];

  final List<Map<String, dynamic>> posts = const [
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

  List<Map<String, dynamic>> get _currentPosts =>
      widget.isDemoMode ? posts : _livePosts;
  List<Map<String, dynamic>> get _currentChallenges =>
      widget.isDemoMode ? demoChallenges : _liveChallenges;

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
                      widget.isDemoMode
                          ? 'welcome back\nto the stars'
                          : 'welcome back\n${_username ?? 'to the stars'}',
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
                              children: _currentChallenges.isEmpty
                                  ? [
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Center(
                                          child: Text(
                                            'No challenges yet!',
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]
                                  : _currentChallenges
                                        .map(
                                          (c) =>
                                              ChallengeCard(challenge: c),
                                        )
                                        .toList(),
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
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (_currentPosts.isEmpty)
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
                    ..._currentPosts.map((post) => PostCard(post: post)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
