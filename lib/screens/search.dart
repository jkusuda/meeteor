import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents a recent search entry.
class RecentSearch {
  final String query;
  final bool isProfile;
  final String? username;
  final String? avatarInitial;

  const RecentSearch({
    required this.query,
    this.isProfile = false,
    this.username,
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
        _isSearching = false;
      });
      return;
    }
    _searchUsers(query);
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isSearching = true);
    try {
      final rows = await Supabase.instance.client
          .from('users')
          .select('id, username, avatar_id')
          .ilike('username', '%$query%')
          .limit(10);
      if (mounted) {
        setState(() {
          _userResults = List<Map<String, dynamic>>.from(rows);
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _submitTextSearch(String query) {
    if (query.trim().isEmpty) return;
    // Add to recent searches (text type)
    recentSearches.removeWhere(
        (r) => !r.isProfile && r.query == query.trim());
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
        username: username,
        avatarInitial:
            username.isNotEmpty ? username[0].toUpperCase() : '?',
      ),
    );
    if (recentSearches.length > 20) recentSearches.removeLast();

    Navigator.of(context).pop(username);
  }

  void _tapRecentSearch(RecentSearch recent) {
    Navigator.of(context).pop(recent.query);
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
    if (_userResults.isEmpty) {
      return Center(
        child: Text('No users found.',
            style: TextStyle(color: AppColors.thistle)),
      );
    }
    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        final username = user['username'] as String? ?? 'unknown';
        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.vintageLavender,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            '@$username',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          onTap: () => _selectUser(user),
        );
      },
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
              child: Text(
                recent.avatarInitial ?? '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '@${recent.username}',
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
