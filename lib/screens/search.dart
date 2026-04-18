import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

/// Represents a recent search entry.
class RecentSearch {
  final String query;
  final bool isProfile;
  final bool isTag;
  final String? userId; // Store the ID for direct navigation
  final String? username;
  final String? avatarId; // Store the actual avatar ID/URL
  final String? avatarInitial;

  const RecentSearch({
    required this.query,
    this.isProfile = false,
    this.isTag = false,
    this.userId,
    this.username,
    this.avatarId,
    this.avatarInitial,
  });
}

/// Global recent searches list, persists across navigations within session.
final List<RecentSearch> recentSearches = [];

class SearchPage extends StatefulWidget {
  /// Optional callback to apply a search back on the explore page.
  final void Function(String query)? onSearch;

  const SearchPage({super.key, this.onSearch});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _userResults = [];
  List<Map<String, dynamic>> _tagResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
    // Auto-focus the search bar when entering this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _userResults = [];
        _tagResults = [];
        _isSearching = false;
      });
      return;
    }
    _searchUsersAndTags(query);
  }

  Future<void> _searchUsersAndTags(String query) async {
    setState(() => _isSearching = true);
    try {
      final client = Supabase.instance.client;

      // Search users and tags in parallel
      final results = await Future.wait([
        client
            .from('users')
            .select('id, username, avatar_id')
            .ilike('username', '%$query%')
            .limit(10),
        client
            .from('tags')
            .select('id, name, category')
            .ilike('name', '%$query%')
            .limit(10),
      ]);

      if (mounted) {
        setState(() {
          _userResults = List<Map<String, dynamic>>.from(results[0]);
          _tagResults = List<Map<String, dynamic>>.from(results[1]);
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _submitTextSearch(String query) {
    if (query.trim().isEmpty) return;
    // Add to recent searches (text type)
    recentSearches.removeWhere(
        (r) => !r.isProfile && !r.isTag && r.query == query.trim());
    recentSearches.insert(
      0,
      RecentSearch(query: query.trim()),
    );
    if (recentSearches.length > 20) recentSearches.removeLast();

    Navigator.of(context).pop(query.trim());
  }

  void _selectUser(Map<String, dynamic> user) {
    final username = user['username'] as String? ?? '';
    // Add to recent searches (profile type)
    recentSearches.removeWhere(
        (r) => r.isProfile && r.username == username);
    recentSearches.insert(
      0,
      RecentSearch(
        query: username,
        isProfile: true,
        userId: user['id'],
        username: username,
        avatarId: user['avatar_id'],
        avatarInitial: username.isNotEmpty ? username[0].toUpperCase() : '?',
      ),
    );
    if (recentSearches.length > 20) recentSearches.removeLast();

    final userId = user['id'];
    if (userId != null) {
      context.push('/profile/$userId');
    } else {
      Navigator.of(context).pop(username);
    }
  }

  void _selectTag(Map<String, dynamic> tag) {
    final tagName = tag['name'] as String? ?? '';
    // Add to recent searches (tag type)
    recentSearches.removeWhere(
        (r) => r.isTag && r.query == tagName);
    recentSearches.insert(
      0,
      RecentSearch(
        query: tagName,
        isTag: true,
      ),
    );
    if (recentSearches.length > 20) recentSearches.removeLast();

    Navigator.of(context).pop(tagName);
  }

  void _tapRecentSearch(RecentSearch recent) {
    if (recent.isProfile && recent.userId != null) {
      context.push('/profile/${recent.userId}');
    } else {
      Navigator.of(context).pop(recent.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final showResults = query.isNotEmpty;

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
            child: Column(
              children: [
                // Search bar with back arrow
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: AppColors.honeyBronze,
                    showCursor: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submitTextSearch,
                    decoration: InputDecoration(
                      hintText: null,
                      prefixIcon: IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: AppColors.honeyBronze),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                            color: AppColors.honeyBronze, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                            color: AppColors.honeyBronze, width: 1),
                      ),
                    ),
                  ),
                ),
                // Content: live results or recent searches
                Expanded(
                  child: showResults
                      ? _buildLiveResults()
                      : _buildRecentSearches(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasUsers = _userResults.isNotEmpty;
    final hasTags = _tagResults.isNotEmpty;

    if (!hasUsers && !hasTags) {
      return Center(
        child: Text('No results found.',
            style: TextStyle(color: AppColors.thistle)),
      );
    }

    return ListView(
      children: [
        // Tags section
        if (hasTags) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Tags',
              style: TextStyle(
                color: AppColors.honeyBronze,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._tagResults.map((tag) {
            final tagName = tag['name'] as String? ?? '';
            final category = tag['category'] as String? ?? 'subject';
            final isChallenge = category == 'challenge';
            return ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChallenge
                      ? AppColors.honeyBronze.withValues(alpha: 0.2)
                      : AppColors.vintageLavender.withValues(alpha: 0.3),
                  border: Border.all(
                    color: isChallenge
                        ? AppColors.honeyBronze
                        : AppColors.vintageLavender,
                    width: 1,
                  ),
                ),
                child: Icon(
                  isChallenge ? Icons.emoji_events_rounded : Icons.tag,
                  color: isChallenge
                      ? AppColors.honeyBronze
                      : AppColors.vintageLavender,
                  size: 16,
                ),
              ),
              title: Text(
                tagName,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                isChallenge ? 'Challenge' : 'Tag',
                style: TextStyle(color: AppColors.thistle, fontSize: 11),
              ),
              onTap: () => _selectTag(tag),
            );
          }),
        ],
        // Users section
        if (hasUsers) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Users',
              style: TextStyle(
                color: AppColors.honeyBronze,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._userResults.map((user) {
            final username = user['username'] as String? ?? 'unknown';
            final avatarId = user['avatar_id'] as String?;
            return ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.vintageLavender,
                backgroundImage: (avatarId != null && avatarId.startsWith('http'))
                    ? NetworkImage(avatarId)
                    : null,
                child: (avatarId == null || avatarId.isEmpty)
                    ? Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : (!avatarId.startsWith('http'))
                        ? Text(avatarId, style: const TextStyle(fontSize: 18))
                        : null,
              ),
              title: Text(
                '@$username',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              onTap: () => _selectUser(user),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildRecentSearches() {
    if (recentSearches.isEmpty) {
      return Center(
        child: Text('No recent searches.',
            style: TextStyle(color: AppColors.thistle)),
      );
    }
    return ListView.builder(
      itemCount: recentSearches.length,
      itemBuilder: (context, index) {
        final recent = recentSearches[index];
        if (recent.isProfile) {
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.vintageLavender,
              backgroundImage: (recent.avatarId != null && recent.avatarId!.startsWith('http'))
                  ? NetworkImage(recent.avatarId!)
                  : null,
              child: (recent.avatarId == null || recent.avatarId!.isEmpty)
                  ? Text(
                      recent.avatarInitial ?? '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : (!recent.avatarId!.startsWith('http'))
                      ? Text(recent.avatarId!, style: const TextStyle(fontSize: 18))
                      : null,
            ),
            title: Text(
              '@${recent.username}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            onTap: () => _tapRecentSearch(recent),
          );
        } else if (recent.isTag) {
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.vintageLavender, width: 1),
              ),
              child: Icon(Icons.tag,
                  color: AppColors.vintageLavender, size: 16),
            ),
            title: Text(
              recent.query,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            onTap: () => _tapRecentSearch(recent),
          );
        } else {
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.vintageLavender, width: 1),
              ),
              child: Icon(Icons.search,
                  color: AppColors.thistle, size: 18),
            ),
            title: Text(
              recent.query,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            onTap: () => _tapRecentSearch(recent),
          );
        }
      },
    );
  }
}
