import '../models/models.dart';
import 'ecommerce_search_service.dart';

/// NLP parsing, recommendations, behavioral learning
class AIRecommendationService {
  final EcommerceSearchService _ecommerceSearch;
  final AnalyticsService _analytics;

  AIRecommendationService(this._ecommerceSearch, this._analytics);

  /// Parse natural language query into structured SearchRequest
  Future<SearchRequest> parseNaturalLanguageQuery(String query) async {
    final lower = query.toLowerCase();

    // Extract sort order
    SearchSortOrder sort = SearchSortOrder.relevance;
    if (lower.contains('cheapest') || lower.contains('lowest price')) {
      sort = SearchSortOrder.priceLowToHigh;
    } else if (lower.contains('best rated') || lower.contains('top rated')) {
      sort = SearchSortOrder.ratingHighToLow;
    } else if (lower.contains('most reviewed') ||
        lower.contains('popular')) {
      sort = SearchSortOrder.mostReviews;
    }

    // Extract source
    EcommerceSource source = EcommerceSource.all;
    if (lower.contains('amazon')) source = EcommerceSource.amazon;
    if (lower.contains('flipkart')) source = EcommerceSource.flipkart;
    if (lower.contains('walmart')) source = EcommerceSource.walmart;

    // Extract price range
    double? minPrice, maxPrice;
    final pricePattern = RegExp(r'under\s*[₹$]?\s*(\d+[,\d]*)');
    final match = pricePattern.firstMatch(lower);
    if (match != null) {
      maxPrice = double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    final abovePattern = RegExp(r'(?:above|over)\s*[₹$]?\s*(\d+[,\d]*)');
    final aboveMatch = abovePattern.firstMatch(lower);
    if (aboveMatch != null) {
      minPrice =
          double.tryParse(aboveMatch.group(1)!.replaceAll(',', ''));
    }

    // Extract brand
    String? brand;
    for (final b in [
      'Samsung', 'Apple', 'Sony', 'LG', 'OnePlus', 'Xiaomi',
      'Google', 'Nokia', 'Oppo', 'Vivo', 'Realme'
    ]) {
      if (lower.contains(b.toLowerCase())) {
        brand = b;
        break;
      }
    }

    // Extract category
    String? category;
    final categories = {
      'phone': 'Smartphones',
      'mobile': 'Smartphones',
      'laptop': 'Laptops',
      'tv': 'Television',
      'headphone': 'Audio',
      'earphone': 'Audio',
      'watch': 'Watches',
      'camera': 'Cameras',
      'tablet': 'Tablets',
    };
    for (final entry in categories.entries) {
      if (lower.contains(entry.key)) {
        category = entry.value;
        break;
      }
    }

    // Clean query
    var cleanQuery = query;
    for (final word in [
      'cheapest', 'best rated', 'top rated', 'most reviewed',
      'popular', 'under', 'above', 'over', 'on amazon',
      'on flipkart', 'on walmart',
    ]) {
      cleanQuery = cleanQuery.replaceAll(RegExp(word, caseSensitive: false), '');
    }
    cleanQuery = cleanQuery.replaceAll(RegExp(r'[₹$]\s*\d+[,\d]*'), '').trim();
    if (cleanQuery.isEmpty) cleanQuery = query;

    return SearchRequest(
      query: cleanQuery,
      sortOrder: sort,
      source: source,
      minPrice: minPrice,
      maxPrice: maxPrice,
      brand: brand,
      category: category,
    );
  }

  /// Get personalized recommendations
  Future<List<Product>> getPersonalizedRecommendations(
      UserProfile profile) async {
    final popular = await _analytics.getPopularSearches(5);
    if (popular.isEmpty) return [];

    final request = SearchRequest(
      query: popular.first,
      maxResults: 10,
    );
    final result = await _ecommerceSearch.searchAllPlatforms(request);
    return result.products;
  }

  /// Get similar products
  Future<List<Product>> getSimilarProducts(Product product) async {
    final query = '${product.brand ?? ''} ${product.category ?? product.name}';
    final request = SearchRequest(query: query.trim(), maxResults: 10);
    final result = await _ecommerceSearch.searchAllPlatforms(request);
    return result.products
        .where((p) => p.name != product.name)
        .take(5)
        .toList();
  }

  /// Generate AI product summary
  Future<String> generateProductSummary(Product product) async {
    final rating = product.averageRating.toStringAsFixed(1);
    final reviews = product.numberOfRatings;
    final price = product.price.toStringAsFixed(2);

    final verdict = product.averageRating >= 4.0
        ? 'Highly recommended'
        : product.averageRating >= 3.0
            ? 'Good choice'
            : 'Consider alternatives';

    return '$verdict — ${product.name} priced at ₹$price '
        'with $rating★ rating from $reviews reviews on ${product.source}. '
        '${product.brand != null ? "Brand: ${product.brand}. " : ""}'
        '${product.category != null ? "Category: ${product.category}." : ""}';
  }

  /// Get recommendation text for products
  Future<String> getRecommendation(
      String query, List<Product> products) async {
    if (products.isEmpty) return 'No products found for "$query".';

    final cheapest = products.reduce((a, b) => a.price < b.price ? a : b);
    final bestRated = products.reduce(
        (a, b) => a.averageRating > b.averageRating ? a : b);

    return 'For "$query": Best price at ₹${cheapest.price.toStringAsFixed(0)} '
        'on ${cheapest.source}. Highest rated: ${bestRated.name} '
        '(${bestRated.averageRating.toStringAsFixed(1)}★). '
        'Found ${products.length} options across multiple platforms.';
  }
}

/// Analytics service for search tracking
class AnalyticsService {
  final dynamic _db; // ProductDatabase

  AnalyticsService(this._db);

  Future<void> recordSearch(
      String query, int resultCount, double responseMs,
      [String? region]) async {
    final entry = SearchAnalyticsEntry(
      query: query,
      resultCount: resultCount,
      responseMs: responseMs,
      region: region,
    );
    await _db.saveSearchAnalytics(entry);

    // Probabilistic 30-day purge (10% chance)
    if (DateTime.now().millisecond % 10 == 0) {
      await _db.purgeOldAnalytics(const Duration(days: 30));
    }
  }

  Future<List<String>> getPopularSearches(int count) =>
      _db.getPopularSearches(count);

  Future<double> getAverageResponseTime() =>
      _db.getAverageResponseTime();
}
