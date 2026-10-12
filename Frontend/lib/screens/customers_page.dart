import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/parapharmacy_service.dart';
import '../services/auth_service.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({Key? key}) : super(key: key);

  @override
  _CustomersPageState createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final ParapharmacyService _parapharmacyService = ParapharmacyService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String _errorMessage = '';
  String _parapharmacyName = '';
  String _parapharmacyId = '';
  List<Map<String, dynamic>> _reviews = [];

  // Filter options
  String _selectedRatingFilter = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredReviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Check if user is authenticated and is a parapharmacy
      final isAuthenticated = await _authService.isAuthenticated();
      final isParapharmacy = await _authService.isParapharmacieUser();

      if (!isAuthenticated || !isParapharmacy) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'You must be logged in as a parapharmacy to view this page';
        });
        return;
      }

      // Get reviews for the authenticated parapharmacy
      final data = await _parapharmacyService.getMyParapharmacyReviews();

      setState(() {
        _parapharmacyName = data['parapharmacyName'] ?? 'My Parapharmacy';
        _parapharmacyId = data['parapharmacyId'] ?? '';
        _reviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
        _filteredReviews = List<Map<String, dynamic>>.from(_reviews);
        _isLoading = false;
      });

      print('Loaded ${_reviews.length} reviews for $_parapharmacyName');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load reviews: $e';
      });
      print(_errorMessage);
    }
  }

  void _filterReviews() {
    setState(() {
      _filteredReviews = _reviews.where((review) {
        // Apply rating filter if needed
        if (_selectedRatingFilter != 'All') {
          final rating = review['rating'] ?? 0;
          final filterRating = int.tryParse(_selectedRatingFilter) ?? 0;
          if (rating != filterRating) {
            return false;
          }
        }

        // Apply search query filter
        if (_searchQuery.isNotEmpty) {
          final comment = review['comment']?.toString().toLowerCase() ?? '';
          final user = review['user']?.toString().toLowerCase() ?? '';
          return comment.contains(_searchQuery.toLowerCase()) ||
              user.contains(_searchQuery.toLowerCase());
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadReviews,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildReviewsContent(),
    );
  }

  Widget _buildReviewsContent() {
    return Column(
      children: [
        // Filter and search section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Reviews: ${_reviews.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search reviews...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        _filterReviews();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedRatingFilter,
                    items: ['All', '1', '2', '3', '4', '5']
                        .map((rating) => DropdownMenuItem<String>(
                              value: rating,
                              child: Text(rating == 'All'
                                  ? 'All Ratings'
                                  : '$rating ★'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRatingFilter = value ?? 'All';
                      });
                      _filterReviews();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Reviews list
        Expanded(
          child: _filteredReviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.comment_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _reviews.isEmpty
                            ? 'No reviews yet'
                            : 'No reviews match your filters',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  color: const Color(0xFF2E7D32),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReviews.length,
                    itemBuilder: (context, index) {
                      final review = _filteredReviews[index];
                      return _buildReviewCard(review);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    // Parse and format the review date
    DateTime reviewDate;
    try {
      reviewDate = DateTime.parse(review['date']);
    } catch (e) {
      reviewDate = DateTime.now();
    }
    final formattedDate = DateFormat('MMM d, yyyy').format(reviewDate);

    // Get review details
    final String userName = review['user'] ?? 'Anonymous';
    final double rating = (review['rating'] ?? 0).toDouble();
    final String comment = review['comment'] ?? '';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F5E9),
                  radius: 20,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      starIndex < rating.floor()
                          ? Icons.star
                          : (starIndex < rating
                              ? Icons.star_half
                              : Icons.star_border),
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
