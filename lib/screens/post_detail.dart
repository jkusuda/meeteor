import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/services/post_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meeteor/core/app_router.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isFocused = false;

  bool get _isLiked => likeStateCache[widget.postId] ?? false;

  @override
  void initState() {
    super.initState();
    _commentFocusNode.addListener(() {
      setState(() => _isFocused = _commentFocusNode.hasFocus);
    });
    likeStateNotifier.addListener(_onLikeStateChanged);
    _fetchData();
  }

  void _onLikeStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final post = await _postService.getPostById(widget.postId);
      final comments = await _postService.fetchComments(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _comments = comments;
          _seedLikeStatus();
        });
      }
    } catch (e) {
      debugPrint('Error fetching post data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _seedLikeStatus() {
    // Only seed if not already in the cache (preserves cross-screen state)
    if (likeStateCache.containsKey(widget.postId)) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _post == null) return;

    if (_post!.containsKey('post_likes')) {
      final likes = _post!['post_likes'] as List<dynamic>? ?? [];
      likeStateCache[widget.postId] = likes.any(
        (like) => (like as Map)['user_id'] == user.id,
      );
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    final originallyLiked = _isLiked;
    likeStateCache[widget.postId] = !originallyLiked;
    likeStateNotifier.value++;
    try {
      await _postService.toggleLike(_post!['id']);
    } catch (e) {
      likeStateCache[widget.postId] = originallyLiked;
      likeStateNotifier.value++;
      debugPrint('Error toggling like: $e');
    }
  }

  void _sharePost() {
    if (_post == null) return;
    final origin = Uri.base.origin;
    final url = '$origin/#/p/${_post!['id']}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
  }

  Future<void> _deletePost() async {
    if (_post == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.spaceIndigo,
        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: AppColors.thistle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.thistle)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await _postService.deletePost(widget.postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully.'), backgroundColor: AppColors.spaceIndigo),
          );
          // Trigger global refresh to update Home/Profile grids immediately
          listRefreshNotifier.value++;
          
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
          );
        }
      }
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      await _postService.addComment(widget.postId, _commentController.text);
      _commentController.clear();
      _commentFocusNode.unfocus();
      final comments = await _postService.fetchComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  @override
  void dispose() {
    likeStateNotifier.removeListener(_onLikeStateChanged);
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.honeyBronze, width: 1.5),
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.honeyBronze,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
          ? const Center(
              child: Text(
                'Post not found',
                style: TextStyle(color: Colors.white),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final postUser = _post!['users'] as Map<String, dynamic>?;
    final username =
        postUser?['username'] as String? ??
        _post!['username'] as String? ??
        'unknown';
    final imageUrl = _post!['imageUrl'] ?? _post!['image_url'];
    final caption = _post!['caption'] as String? ?? '';

    return Stack(
      children: [
        // Starry sky background
        Positioned.fill(
          child: Image.asset('assets/starry_sky_bg_1.png', fit: BoxFit.cover),
        ),
        // Main scrollable content
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.vintageLavender,
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '@$username',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_post!['user_id'] == Supabase.instance.client.auth.currentUser?.id || adminViewEnabledNotifier.value) ...[
                            const Spacer(),
                            SizedBox(
                              width: 32,
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                iconSize: 22,
                                icon: const Icon(Icons.more_horiz, color: Colors.white70),
                                color: AppColors.spaceIndigo,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: AppColors.vintageLavender.withValues(alpha: 0.3), width: 1),
                                ),
                                elevation: 8,
                                offset: const Offset(0, 36),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deletePost();
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    height: 32,
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Delete Post',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Post image
                    if (imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                            size: 50,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Action buttons with borders
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildActionButton(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            _toggleLike,
                            color: _isLiked ? Colors.redAccent : null,
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(Icons.ios_share, _sharePost),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tags
                    _buildTagsRow(_post!),
                    // Caption
                    if (caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          caption,
                          style: TextStyle(
                            color: AppColors.thistle,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Camera settings - always expanded
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Camera Settings',
                            style: TextStyle(
                              color: AppColors.honeyBronze,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Camera: ${_post!['camera'] ?? '-'}',
                            style: TextStyle(
                              color: AppColors.thistle,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'ISO: ${_post!['iso'] ?? '-'}',
                            style: TextStyle(
                              color: AppColors.thistle,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Aperture: ${_post!['aperture'] ?? '-'}',
                            style: TextStyle(
                              color: AppColors.thistle,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Exposure: ${_post!['exposure'] ?? '-'}',
                            style: TextStyle(
                              color: AppColors.thistle,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Comments section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Comments',
                        style: TextStyle(
                          color: AppColors.honeyBronze,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'No comments yet.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final user =
                              comment['users'] as Map<String, dynamic>?;
                          final commentUsername =
                              user?['username'] as String? ?? 'unknown';
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.vintageLavender,
                                  child: Text(
                                    commentUsername.isNotEmpty
                                        ? commentUsername[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '@$commentUsername',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        comment['content'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            // Comment input bar - transparent background
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 8,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: AppColors.honeyBronze,
                      showCursor: true,
                      decoration: InputDecoration(
                        hintText: _isFocused ? null : 'Write a comment...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppColors.vintageLavender,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppColors.honeyBronze,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: AppColors.honeyBronze),
                    onPressed: _submitComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsRow(Map<String, dynamic> post) {
    // Extract tags from the normalized post_tags → tags join structure
    final postTags = post['post_tags'] as List<dynamic>? ?? const [];
    final tags = postTags
        .map((pt) {
          final tagData = (pt as Map<String, dynamic>)['tags'];
          if (tagData is Map<String, dynamic>) {
            return tagData['name']?.toString().trim() ?? '';
          }
          return '';
        })
        .where((tag) => tag.isNotEmpty)
        .toList();

    // Fallback: legacy flat tags array
    if (tags.isEmpty) {
      final legacyTags = (post['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString().trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      if (legacyTags.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: legacyTags.map(_buildTag).toList(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
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
}
