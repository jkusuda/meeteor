import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/services/auth_service.dart';
import 'package:meeteor/services/user_service.dart';
import 'package:meeteor/core/app_router.dart';

class SettingsPage extends StatefulWidget {
  final String? initialUsername;
  final String? initialBio;
  final String? initialAvatarId;
  final bool adminViewEnabled;
  final VoidCallback? onToggleAdminView;

  const SettingsPage({
    super.key,
    this.initialUsername,
    this.initialBio,
    this.initialAvatarId,
    this.adminViewEnabled = false,
    this.onToggleAdminView,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _userService = UserService();
  final AuthService _authService = AuthService();
  String? _email;
  String? _username;
  String? _avatarId;
  String _bio = '';
  bool _isAdminUser = false;

  final List<String> _spaceIcons = [
    '👨‍🚀',
    '👩‍🚀',
    '🪐',
    '🚀',
    '🛰️',
    '☄️',
    '🌕',
    '✨',
    '🌙',
    '☀️',
    '🛸',
    '👽',
  ];

  @override
  void initState() {
    super.initState();
    _username = widget.initialUsername;
    _bio = widget.initialBio ?? '';
    _avatarId = widget.initialAvatarId;
    
    final session = Supabase.instance.client.auth.currentSession;
    _email = session?.user.email;
    _loadAdminState();
    _fetchProfile();
  }

  Future<void> _loadAdminState() async {
    final hasAccess = await _authService.hasAdminAccess();
    if (!mounted) return;
    setState(() => _isAdminUser = hasAccess);
  }

  Future<void> _fetchProfile() async {
    final data = await _userService.getProfile();
    if (mounted && data != null) {
      setState(() {
        _username = data['username'] as String?;
        _bio = (data['bio'] as String?) ?? '';
        _avatarId = data['avatar_id'] as String?;
      });
    }
  }

  Future<void> _showAvatarPicker() async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          decoration: BoxDecoration(
            color: AppColors.spaceIndigo,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.vintageLavender.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Select Your Avatar',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.thistle,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _spaceIcons.length,
                itemBuilder: (context, index) {
                  final icon = _spaceIcons[index];
                  final isSelected = _avatarId == icon;
                  return GestureDetector(
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      try {
                        await _userService.updateProfile({'avatar_id': icon});
                        if (mounted) {
                          setState(() => _avatarId = icon);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Avatar successfully changed!'),
                              backgroundColor: AppColors.spaceIndigo,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(bottom: 5, left: 16, right: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Avatar update error: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update avatar: $e'),
                              backgroundColor: AppColors.spaceIndigo,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(bottom: 5, left: 16, right: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.honeyBronze.withOpacity(0.2)
                            : AppColors.prussianBlue.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.honeyBronze
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(icon, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog({
    required String title,
    required String initialValue,
    required String hint,
    int? maxLength,
    required Future<void> Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isOverLimit =
                maxLength != null && controller.text.length > maxLength;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.spaceIndigo,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.thistle,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.thistle.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    cursorColor: AppColors.honeyBronze,
                    maxLength: maxLength,
                    maxLines: title.contains('Bio') ? 4 : 1,
                    autofocus: true,
                    style: GoogleFonts.dmSans(color: AppColors.thistle),
                    onChanged: (val) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.dmSans(
                        color: AppColors.thistle.withOpacity(0.3),
                      ),
                      filled: true,
                      fillColor: AppColors.prussianBlue.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      counterStyle: GoogleFonts.dmSans(
                        color: isOverLimit
                            ? Colors.redAccent
                            : AppColors.vintageLavender,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOverLimit
                            ? AppColors.vintageLavender.withOpacity(0.4)
                            : AppColors.honeyBronze,
                        foregroundColor: isOverLimit
                            ? AppColors.thistle.withOpacity(0.5)
                            : AppColors.prussianBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isOverLimit
                          ? null
                          : () async {
                              final value = controller.text.trim();
                              Navigator.of(ctx).pop();
                              if (title.contains('Bio') || value.isNotEmpty) {
                                await onSave(value);
                              }
                            },
                      child: Text(
                        'Save',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => controller.dispose());
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.vintageLavender,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    String? value,
    VoidCallback? onTap,
    Color? labelColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.spaceIndigo.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.vintageLavender.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.vintageLavender),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? AppColors.thistle,
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.thistle.withOpacity(0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.vintageLavender.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/starry_sky_bg_1.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.thistle,
                        ),
                      ),
                      Text(
                        'Settings',
                        style: GoogleFonts.dmSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.thistle,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Account'),
                          const SizedBox(height: 16),
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.spaceIndigo,
                                    border: Border.all(
                                      color: AppColors.vintageLavender,
                                      width: 2,
                                    ),
                                    image:
                                        (_avatarId != null &&
                                            _avatarId!.startsWith('http'))
                                        ? DecorationImage(
                                            image: NetworkImage(_avatarId!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child:
                                      (_avatarId == null ||
                                          _avatarId!.isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          size: 44,
                                          color: AppColors.thistle,
                                        )
                                      : (!_avatarId!.startsWith('http'))
                                      ? Center(
                                          child: Text(
                                            _avatarId!,
                                            style: const TextStyle(
                                              fontSize: 44,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showAvatarPicker,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.honeyBronze,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 18,
                                        color: AppColors.prussianBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _settingsTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _email ?? '—',
                          ),
                          _settingsTile(
                            icon: Icons.alternate_email,
                            label: 'Username',
                            value: '@${_username ?? 'username'}',
                            onTap: () => _showEditDialog(
                              title: 'Edit Username',
                              initialValue: _username ?? '',
                              hint: 'New username',
                              maxLength: 30,
                              onSave: (val) async {
                                try {
                                  await _userService.updateProfile({
                                    'username': val,
                                  });
                                  if (mounted) {
                                    setState(() => _username = val);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Username saved!'),
                                        backgroundColor: AppColors.spaceIndigo,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(bottom: 5, left: 16, right: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Username error: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update username: $e'),
                                        backgroundColor: AppColors.spaceIndigo,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(bottom: 5, left: 16, right: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          _settingsTile(
                            icon: Icons.info_outline,
                            label: 'Bio',
                            value: _bio.isEmpty ? 'Tap to add bio' : _bio,
                            onTap: () => _showEditDialog(
                              title: 'Edit Bio',
                              initialValue: _bio,
                              hint: 'About you...',
                              maxLength: 200,
                              onSave: (val) async {
                                try {
                                  await _userService.updateProfile({
                                    'bio': val,
                                  });
                                  if (mounted) {
                                    setState(() => _bio = val);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Bio saved!'),
                                        backgroundColor: AppColors.spaceIndigo,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(bottom: 5, left: 16, right: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Bio error: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update bio: $e'),
                                        backgroundColor: AppColors.spaceIndigo,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(bottom: 5, left: 16, right: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          if (_isAdminUser && widget.onToggleAdminView != null) ...[
                            const SizedBox(height: 24),
                            _sectionLabel('Admin Settings'),
                            ValueListenableBuilder<bool>(
                              valueListenable: adminViewEnabledNotifier,
                              builder: (context, adminViewEnabled, _) => _settingsTile(
                                icon: Icons.admin_panel_settings_rounded,
                                label: adminViewEnabled
                                    ? 'Switch to User View'
                                    : 'Switch to Admin View',
                                onTap: widget.onToggleAdminView,
                                labelColor: AppColors.honeyBronze,
                                iconColor: AppColors.honeyBronze,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _sectionLabel('Account Actions'),
                          _settingsTile(
                            icon: Icons.logout,
                            label: 'Sign Out',
                            onTap: () async => AuthService().signOut(),
                            labelColor: Colors.redAccent.shade100,
                            iconColor: Colors.redAccent.shade100,
                          ),
                        ],
                      ),
                    ),
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
