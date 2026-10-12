import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> recentSearches = [
    'cerave cleanser',
    'Light gel cream',
    'Bubble moisturizer',
    'Ordinary',
    'Clinique',
  ];

  List<Map<String, dynamic>> categories = [
    {'icon': Icons.face_retouching_natural, 'name': 'Skincare'},
    {'icon': Icons.cleaning_services, 'name': 'Cleansers'},
    {'icon': Icons.water_drop, 'name': 'Moisturizers'},
    {'icon': Icons.remove_red_eye, 'name': 'Eye Care'},
    {'icon': Icons.sunny, 'name': 'Sun Care'},
  ];

  List<String> suggestions = [];
  bool isSearching = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    setState(() {
      suggestions = [
        '$query cream',
        '$query serum',
        '$query cleanser',
        '$query moisturizer',
      ];
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      searchQuery = '';
      suggestions = [];
    });
  }

  void _clearAllRecent() {
    setState(() {
      recentSearches.clear();
    });
  }

  void _removeRecentSearch(String search) {
    setState(() {
      recentSearches.remove(search);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      isSearching = query.isNotEmpty;
    });
    _updateSuggestions(query);
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGreen = Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: primaryGreen),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon:
                                  const Icon(Icons.clear, color: primaryGreen),
                              onPressed: _clearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: lightGreen.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                  if (!isSearching) ...[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((category) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    category['icon'],
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(category['name']),
                                ],
                              ),
                              selected: false,
                              onSelected: (bool selected) {},
                              backgroundColor: primaryGreen.withOpacity(0.8),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: suggestions.isNotEmpty
                    ? _buildSuggestions()
                    : isSearching && searchQuery.length > 2
                        ? _buildNotFound()
                        : _buildRecentSearches(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(
            Icons.search,
            color: Color(0xFF2E7D32),
          ),
          title: Text(
            suggestions[index],
            style: const TextStyle(fontSize: 16),
          ),
          onTap: () {
            setState(() {
              _searchController.text = suggestions[index];
              searchQuery = suggestions[index];
              suggestions = [];
            });
          },
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    if (recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No recent searches',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              TextButton.icon(
                onPressed: _clearAllRecent,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Color(0xFF2E7D32),
                ),
                label: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recentSearches.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(
                  Icons.history,
                  color: Color(0xFF2E7D32),
                ),
                title: Text(
                  recentSearches[index],
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeRecentSearch(recentSearches[index]),
                  color: Colors.grey,
                ),
                onTap: () {
                  setState(() {
                    _searchController.text = recentSearches[index];
                    searchQuery = recentSearches[index];
                    isSearching = true;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _clearSearch,
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
