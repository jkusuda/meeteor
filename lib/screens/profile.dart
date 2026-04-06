import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/screens/settings.dart';
import 'package:meeteor/widgets/profile_post_card.dart';
import 'package:meeteor/services/user_service.dart';

class ProfilePage extends StatefulWidget {
  final bool isDemoMode;
  final VoidCallback? onToggleDemo;

  const ProfilePage({
    super.key,
    this.isDemoMode = true,
    this.onToggleDemo,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userService = UserService();
  String? _username;
  String? _displayName;
  String? _bio;
  String? _avatarUrl;
  bool _isLoading = false;

  static const List<Map<String, dynamic>> _demoPosts = [
    { 'imageUrl': 'https://picsum.photos/seed/nebula1/400/400', 'caption': 'Orion Nebula — 30s · f/2.8 · ISO 3200' },
    { 'imageUrl': 'https://picsum.photos/seed/milky1/400/400', 'caption': 'Milky Way arch over the desert' },
    { 'imageUrl': 'https://picsum.photos/seed/moon42/400/400', 'caption': 'Full moon craters in high detail' },
    { 'imageUrl': 'https://picsum.photos/seed/andromeda7/400/400', 'caption': 'Andromeda galaxy widefield' },
    { 'imageUrl': 'https://picsum.photos/seed/saturn9/400/400', 'caption': 'Saturn\'s rings through the eyepiece' },
    { 'imageUrl': 'https://picsum.photos/seed/aurora3/400/400', 'caption': 'Aurora borealis from Iceland 🌌' },
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
        _displayName = data['display_name'] as String?;
        _bio = data['bio'] as String?;
        _avatarUrl = data['avatar_url'] as String?;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // String get _displayUsername => (_displayName != null && _displayName!.isNotEmpty) ? _displayName! : (_username ?? '—');
  String get _displayUsername {
    if (_displayName != null && _displayName!.trim().isNotEmpty) {
      return _displayName!;
    }
    return _username ?? '—'; // Fallback to username (or dash if both are null)
  }
  String get _displayBio => (_bio != null && _bio!.isNotEmpty) ? _bio! : 'Astrophotographer · meeteor member 🔭';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile',
              style: TextStyle(color: AppColors.thistle, fontSize: 24),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await AuthService().signOut();
              },
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
