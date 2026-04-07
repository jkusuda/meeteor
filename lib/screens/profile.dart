import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/screens/settings.dart';
import 'package:meeteor/widgets/profile_post_card.dart';
import 'package:meeteor/core/app_router.dart';

class ProfilePage extends StatefulWidget {
  final bool isDemoMode;
  final VoidCallback? onToggleDemo;
  final bool adminViewEnabled;
  final VoidCallback? onToggleAdminView;

  const ProfilePage({
    super.key,
    this.isDemoMode = true,
    this.onToggleDemo,
    this.adminViewEnabled = false,
    this.onToggleAdminView,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username;
  String? _bio;
  String? _avatarId;
  bool _isLoading = false;

  List<Map<String, dynamic>> _myPosts = [];
  List<Map<String, dynamic>> _likedPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    listRefreshNotifier.addListener(_fetchProfile);
  }



  @override
  void dispose() {
    listRefreshNotifier.removeListener(_fetchProfile);
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    if (_myPosts.isEmpty && _likedPosts.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // Fetch using the standard syntax
        final data = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', session.user.id);

        final postsRes = await Supabase.instance.client
            .from('posts')
            .select()
            .eq('user_id', session.user.id)
            .order('created_at', ascending: false);

        final likesRes = await Supabase.instance.client
            .from('post_likes')
            .select('posts(*)')
            .eq('user_id', session.user.id)
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            if (data.isNotEmpty) {
              final userProfile = data.first;
              _username = userProfile['username'] as String?;
              _bio = userProfile['bio'] as String?;
              _avatarId = userProfile['avatar_id'] as String?;
            }
            _myPosts = List<Map<String, dynamic>>.from(postsRes);
            // Liked posts are nested inside 'posts'
            _likedPosts = List<Map<String, dynamic>>.from(
              likesRes.map((like) => like['posts']).where((p) => p != null),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _username = 'ERR: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _displayUsername => _username ?? 'Guest';
  String get _displayBio => _bio ?? '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.prussianBlue,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 9.0, top: 9.0),
              child: IconButton(
                icon: const Icon(Icons.settings, color: AppColors.thistle),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(
                        initialUsername: _username,
                        initialBio: _bio,
                        initialAvatarId: _avatarId,
                        adminViewEnabled: widget.adminViewEnabled,
                        onToggleAdminView: widget.onToggleAdminView,
                      ),
                    ),
                  ).then((_) => _fetchProfile());
                },
              ),
            ),
          ],
        ),
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.vintageLavender,
                      ),
                    )
                  : Column(
                      children: [
                        // Profile Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            28.0,
                            16.0,
                            24.0,
                            16.0,
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: AppColors.spaceIndigo,
                                backgroundImage:
                                    (_avatarId != null &&
                                        _avatarId!.startsWith('http'))
                                    ? NetworkImage(_avatarId!)
                                    : null,
                                child:
                                    (_avatarId == null || _avatarId!.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 46,
                                        color: AppColors.vintageLavender,
                                      )
                                    : (!_avatarId!.startsWith('http'))
                                    ? Text(
                                        _avatarId!,
                                        style: const TextStyle(fontSize: 46),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 24),

                              // Username & Bio
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _displayUsername,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_displayBio.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _displayBio,
                                        style: GoogleFonts.inter(
                                          color: AppColors.thistle,
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Tabs
                        const TabBar(
                          indicatorColor: AppColors.vintageLavender,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white54,
                          tabs: [
                            Tab(icon: Icon(Icons.grid_on)),
                            Tab(icon: Icon(Icons.favorite)),
                          ],
                        ),

                        // TabBarView for Grids
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Tab 1: My Posts
                              _myPosts.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No posts to display, create your first post today!',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    )
                                  : GridView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: 1,
                                          ),
                                      itemCount: _myPosts.length,
                                      itemBuilder: (context, index) {
                                        final post = _myPosts[index];
                                        return ProfilePostCard(post: post);
                                      },
                                    ),

                              // Tab 2: Liked Posts
                              _likedPosts.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No liked posts yet',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    )
                                  : GridView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: 1,
                                          ),
                                      itemCount: _likedPosts.length,
                                      itemBuilder: (context, index) {
                                        final post = _likedPosts[index];
                                        return ProfilePostCard(post: post);
                                      },
                                    ),
                            ],
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
