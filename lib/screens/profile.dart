import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/screens/settings.dart';
import 'package:meeteor/widgets/profile_post_card.dart';
import 'package:meeteor/services/user_service.dart';
import 'package:meeteor/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final bool isDemoMode;
  final VoidCallback? onToggleDemo;

  const ProfilePage({super.key, this.isDemoMode = true, this.onToggleDemo});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userService = UserService();
  String? _username;
  String? _location;
  String? _bio;
  String? _avatarId;
  bool _isLoading = false;

  static const List<Map<String, dynamic>> _demoPosts = [
    {
      'imageUrl': 'https://picsum.photos/seed/nebula1/400/400',
      'caption': 'Orion Nebula — 30s · f/2.8 · ISO 3200',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/milky1/400/400',
      'caption': 'Milky Way arch over the desert',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/moon42/400/400',
      'caption': 'Full moon craters in high detail',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/andromeda7/400/400',
      'caption': 'Andromeda galaxy widefield',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/saturn9/400/400',
      'caption': 'Saturn\'s rings through the eyepiece',
    },
    {
      'imageUrl': 'https://picsum.photos/seed/aurora3/400/400',
      'caption': 'Aurora borealis from Iceland 🌌',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDemoMode != oldWidget.isDemoMode) _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final data = await _userService.getProfile();

    if (mounted && data != null) {
      setState(() {
        _username = data['username'] as String?;
        _location = data['location'] as String?;
        _bio = data['bio'] as String?;
        _avatarId = data['avatar_id'] as String?;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String get _displayUsername => _username ?? '—';

  String get _displayBio => (_bio != null && _bio!.isNotEmpty)
      ? _bio!
      : 'Astrophotographer · meeteor member 🔭';
      
  String get _displayLocation => (_location != null && _location!.isNotEmpty) 
      ? _location! 
      : 'Earth';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.thistle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 10.0,
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.spaceIndigo,
                              backgroundImage: (_avatarId != null && _avatarId!.startsWith('http'))
                                  ? NetworkImage(_avatarId!)
                                  : null,
                              child: (_avatarId == null || _avatarId!.isEmpty)
                                  ? const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: AppColors.vintageLavender,
                                    )
                                  : (!_avatarId!.startsWith('http')) 
                                      ? Text(_avatarId!, style: const TextStyle(fontSize: 40)) 
                                      : null,
                            ),
                            const SizedBox(width: 20),

                            // Username & Bio
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _displayUsername,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: AppColors.vintageLavender),
                                      const SizedBox(width: 4),
                                      Text(
                                        _displayLocation,
                                        style: GoogleFonts.inter(
                                          color: AppColors.vintageLavender,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _displayBio,
                                    style: GoogleFonts.inter(
                                      color: AppColors.thistle,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Grid of Posts
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                          itemCount: _demoPosts.length,
                          itemBuilder: (context, index) {
                            final post = _demoPosts[index];
                            return ProfilePostCard(post: post);
                          },
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
