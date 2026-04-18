import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/screens/search.dart';
import 'package:meeteor/widgets/shimmer_loading.dart';
import 'package:meeteor/core/app_router.dart'; // listRefreshNotifier
import 'package:supabase_flutter/supabase_flutter.dart';

class ExplorePage extends StatefulWidget {
  final String? initialQuery;
  const ExplorePage({super.key, this.initialQuery});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _activeQuery = widget.initialQuery!;
    }
    _fetchPosts();
    listRefreshNotifier.addListener(_onRefresh);
  }

  @override
  void dispose() {
    listRefreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    // Only show skeleton on initial load
    if (_posts.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final rows = await Supabase.instance.client
          .from('posts')
          .select('*, users(username), post_tags(tags(name))')
          .order('created_at', ascending: false);
      final posts = List<Map<String, dynamic>>.from(rows);
      if (mounted) {
        setState(() {
          _posts = posts;
          // Re-apply active filter if one exists
          if (_activeQuery.isNotEmpty) {
            _applyFilter(_activeQuery);
          } else {
            _filtered = posts;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching explore posts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String query) {
    _activeQuery = query;
    if (query.isEmpty) {
      setState(() => _filtered = _posts);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _filtered = _posts.where((post) {
        final caption = (post['caption'] as String? ?? '').toLowerCase();
        final user = post['users'] as Map<String, dynamic>?;
        final username = (user?['username'] as String? ?? '').toLowerCase();
        // Also match against tag names
        final postTags = post['post_tags'] as List<dynamic>? ?? const [];
        final tagMatch = postTags.any((pt) {
          final tagData = (pt as Map<String, dynamic>)['tags'];
          if (tagData is Map<String, dynamic>) {
            final tagName = (tagData['name']?.toString() ?? '').toLowerCase();
            return tagName.contains(lower);
          }
          return false;
        });
        return caption.contains(lower) || username.contains(lower) || tagMatch;
      }).toList();
    });
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SearchPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    if (result != null && mounted) {
      _applyFilter(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/starry_sky_bg_1.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Tappable search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: GestureDetector(
                    onTap: _openSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppColors.vintageLavender, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: AppColors.thistle),
                          const SizedBox(width: 12),
                          Text(
                            _activeQuery.isEmpty
                                ? 'Search...'
                                : _activeQuery,
                            style: TextStyle(
                              color: _activeQuery.isEmpty
                                  ? Colors.white54
                                  : Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          if (_activeQuery.isNotEmpty) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                _applyFilter('');
                              },
                              child: Icon(Icons.close,
                                  color: AppColors.thistle, size: 18),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Grid
                Expanded(
                  child: _isLoading
                      ? const ExploreGridSkeleton()
                      : _filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No posts found.',
                                style: TextStyle(color: AppColors.thistle),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, bottom: 88),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final post = _filtered[index];
                                final imageUrl =
                                    post['imageUrl'] ?? post['image_url'];
                                return GestureDetector(
                                  onTap: () =>
                                      context.push('/p/${post['id']}'),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: imageUrl != null
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: AppColors.spaceIndigo,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.white54,
                                            ),
                                          ),
                                  ),
                                );
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
