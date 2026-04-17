import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/services/post_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/core/app_router.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();

  bool get _isLiked => likeStateCache[widget.post['id']?.toString()] ?? false;

  @override
  void initState() {
    super.initState();
    _initLikeStatus();
    likeStateNotifier.addListener(_onLikeStateChanged);
  }

  @override
  void dispose() {
    likeStateNotifier.removeListener(_onLikeStateChanged);
    super.dispose();
  }

  void _onLikeStateChanged() {
    if (mounted) setState(() {});
  }

  void _initLikeStatus() {
    final postId = widget.post['id']?.toString();
    if (postId == null) return;
    // Only seed the cache if not already set (preserves cross-screen state)
    if (likeStateCache.containsKey(postId)) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (widget.post.containsKey('post_likes')) {
      final likes = widget.post['post_likes'] as List<dynamic>? ?? [];
      likeStateCache[postId] = likes.any(
        (like) => (like as Map)['user_id'] == user.id,
      );
    } else if (widget.post.containsKey('is_liked_by_user')) {
      likeStateCache[postId] = widget.post['is_liked_by_user'] == true;
    }
  }

  Future<void> _toggleLike() async {
    final postId = widget.post['id']?.toString();
    if (postId == null) return;
    final originallyLiked = _isLiked;
    likeStateCache[postId] = !originallyLiked;
    likeStateNotifier.value++;
    try {
      await _postService.toggleLike(widget.post['id']);
    } catch (e) {
      likeStateCache[postId] = originallyLiked;
      likeStateNotifier.value++;
      debugPrint('Error toggling like: $e');
    }
  }

  void _sharePost() {
    final postId = widget.post['id'];
    // For Flutter web, we can construct the full URL. If origin is not available, we use current base.
    final origin = Uri.base.origin;
    final url =
        '$origin/#/p/$postId'; // Often flutter web uses hash routing unless configured otherwise
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
  }

  void _goToComments() {
    context.push('/p/${widget.post['id']}');
  }

  Widget _buildTagsRow(Map<String, dynamic> post) {
    final tags = (post['tags'] as List<dynamic>? ?? const [])
        .map((tag) => tag.toString().trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: tags.map(_buildTag).toList(),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.vintageLavender.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white54, width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color ?? Colors.white, width: 0.5),
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postUser = widget.post['users'] as Map<String, dynamic>?;
    final username =
        postUser?['username'] as String? ??
        widget.post['username'] as String? ??
        'unknown';

    return GestureDetector(
      onTap: () => context.push('/p/${widget.post['id']}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.spaceIndigo,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.vintageLavender,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '@$username',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              child:
                  (widget.post['imageUrl'] ?? widget.post['image_url']) != null
                  ? Image.network(
                      widget.post['imageUrl'] ?? widget.post['image_url'],
                      width: double.infinity,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.black45,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 50,
                      ),
                    ),
            ),
            GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildActionButton(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      () {
                        _toggleLike();
                      },
                      color: _isLiked ? Colors.redAccent : null,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      Icons.chat_bubble_outline,
                      _goToComments,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(Icons.ios_share, _sharePost),
                  ],
                ),
              ),
            ),
            _buildTagsRow(widget.post),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Text(
                widget.post['caption'] ?? '',
                style: TextStyle(color: AppColors.thistle, fontSize: 14),
              ),
            ),
            Theme(
              data: ThemeData(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                minTileHeight: 36,
                title: Text(
                  'Camera Settings',
                  style: TextStyle(color: AppColors.honeyBronze, fontSize: 13),
                ),
                iconColor: AppColors.honeyBronze,
                collapsedIconColor: AppColors.honeyBronze,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Camera: ${widget.post['camera'] ?? '-'}',
                            style: TextStyle(
                              color: AppColors.thistle,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'ISO: ${widget.post['iso'] ?? '-'}',
                            style: TextStyle(
                              color: AppColors.thistle,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Aperture: ${widget.post['aperture'] ?? '-'}',
                            style: TextStyle(
                              color: AppColors.thistle,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Exposure: ${widget.post['exposure'] ?? '-'}',
                            style: TextStyle(
                              color: AppColors.thistle,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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
