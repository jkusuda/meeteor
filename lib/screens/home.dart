// home screen code
import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/core/app_router.dart'; // listRefreshNotifier

import 'package:meeteor/widgets/challenge_card.dart';
import 'package:meeteor/widgets/post_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
    listRefreshNotifier.addListener(_fetchSupabaseData);
  }

  @override
  void dispose() {
    listRefreshNotifier.removeListener(_fetchSupabaseData);
    super.dispose();
  }



  Future<void> _fetchSupabaseData() async {
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
                      'welcome back\n${_username ?? 'to the stars'}',
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
                              children: _liveChallenges.isEmpty
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
                                  : _liveChallenges
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
                  else if (_livePosts.isEmpty)
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
                    ..._livePosts.map((post) => PostCard(post: post)),
                  const SizedBox(height: 120), // Extra space for the bottom navbar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
