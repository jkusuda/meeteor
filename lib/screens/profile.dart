import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/screens/settings.dart';
import 'package:meeteor/widgets/profile_post_card.dart';
import 'package:meeteor/core/app_router.dart';
import 'package:meeteor/widgets/shimmer_loading.dart';

class ProfilePage extends StatefulWidget {
  final bool isDemoMode;
  final VoidCallback? onToggleDemo;
  final bool adminViewEnabled;
  final VoidCallback? onToggleAdminView;
  final String? userId;

  const ProfilePage({
    super.key,
    this.isDemoMode = true,
    this.onToggleDemo,
    this.adminViewEnabled = false,
    this.onToggleAdminView,
    this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username;
  String? _bio;
  String? _avatarId;
  bool _isLoading = true;

  List<Map<String, dynamic>> _myPosts = [];
  List<Map<String, dynamic>> _likedPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    listRefreshNotifier.addListener(_fetchProfile);
    likeStateNotifier.addListener(_onLikeStateChanged);
  }

  void _onLikeStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    listRefreshNotifier.removeListener(_fetchProfile);
    likeStateNotifier.removeListener(_onLikeStateChanged);
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    if (_myPosts.isEmpty && _likedPosts.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final targetUserId = widget.userId ?? session.user.id;
        
        final data = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', targetUserId);

        final postsRes = await Supabase.instance.client
            .from('posts')
            .select('*, users(username, avatar_id), post_likes(user_id), post_tags(tags(name, category))')
            .eq('user_id', targetUserId)
            .order('created_at', ascending: false);

        List<dynamic> likesRes = [];
        if (_isCurrentUser) {
          likesRes = await Supabase.instance.client
              .from('post_likes')
              .select('posts(*, users(username, avatar_id), post_likes(user_id), post_tags(tags(name, category)))')
              .eq('user_id', session.user.id)
              .order('created_at', ascending: false);
        }

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
            // Seed like cache: all liked posts are liked by current user
            for (final post in _likedPosts) {
              final pid = post['id']?.toString();
              if (pid != null && !likeStateCache.containsKey(pid)) {
                likeStateCache[pid] = true;
              }
            }
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

  bool get _isCurrentUser => widget.userId == null || widget.userId == Supabase.instance.client.auth.currentSession?.user.id;

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
          leading: widget.userId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          actions: [
            if (_isCurrentUser)
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
                  ? const ProfileSkeleton()
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
                        if (_isCurrentUser)
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
                          child: _isCurrentUser
                              ? TabBarView(
                                  children: [
                                    // Tab 1: My Posts
                                    _buildGrid(_myPosts, 'No posts to display, create your first post today!'),
                                    // Tab 2: Liked Posts
                                    _buildGrid(_likedPosts, 'No liked posts yet'),
                                  ],
                                )
                              : _buildGrid(_myPosts, 'This user has no posts yet.'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> posts, String emptyMessage) {
    if (posts.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: Colors.white54)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 88),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return ProfilePostCard(post: post);
      },
    );
  }
}
