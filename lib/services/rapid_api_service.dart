import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'connectivity_service.dart';

/// RapidAPI multi-platform e-commerce search service.
///
/// Supports multiple RapidAPI endpoints for real product search:
/// - Real-Time Product Search (Google Shopping aggregation)
/// - Amazon Product Data
/// - Walmart Product Search
/// - eBay Product Search
///
/// All requests use the single RapidAPI key with different host headers.
class RapidApiService {
  final http.Client _httpClient;
  final ApiConfiguration _apiConfig;
  final ConnectivityService _connectivity;

  RapidApiService(this._httpClient, this._apiConfig, this._connectivity);

  bool get isAvailable =>
      _apiConfig.enableRapidApi && _apiConfig.rapidApiKey.isNotEmpty;

  Map<String, String> _headers(String host) => {
        'X-RapidAPI-Key': _apiConfig.rapidApiKey,
        'X-RapidAPI-Host': host,
      };

  // ──────────────────────────────────────────────
  // 1. Real-Time Product Search (Google Shopping)
  //    Host: real-time-product-search.p.rapidapi.com
  //    Aggregates results from Google Shopping across all e-commerce platforms
  // ──────────────────────────────────────────────
  Future<List<Product>> searchGoogleShopping(
    String query, {
    int maxResults = 20,
    String country = 'in',
    String? category,
  }) async {
    if (!isAvailable || !_connectivity.isConnected) return [];

    try {
      final uri = Uri.https(
        'real-time-product-search.p.rapidapi.com',
        '/search',
        {
          'q': query,
          'country': country,
          'language': 'en',
          'limit': maxResults.toString(),
          if (category != null) 'product_condition': 'NEW',
        },
      );

      final response = await _httpClient
          .get(uri, headers: _headers('real-time-product-search.p.rapidapi.com'))
          .timeout(const Duration(seconds: 15));

      dev.log('RapidAPI GoogleShopping: status=${response.statusCode} '
          'body=${response.body.length} bytes', name: 'RapidAPI');

      if (response.statusCode == 200) {
        final results = _parseGoogleShoppingResults(response.body);
        dev.log('RapidAPI GoogleShopping: parsed ${results.length} products',
            name: 'RapidAPI');
        return results;
      } else {
        dev.log('RapidAPI GoogleShopping ERROR: ${response.statusCode} '
            '${response.body.substring(0, (response.body.length > 200 ? 200 : response.body.length))}',
            name: 'RapidAPI');
      }
    } catch (e) {
      dev.log('RapidAPI GoogleShopping EXCEPTION: $e', name: 'RapidAPI');
    }
    return [];
  }

  List<Product> _parseGoogleShoppingResults(String body) {
    try {
      final json = jsonDecode(body);
      final data = json['data'] as List? ?? [];

      return data.map<Product>((item) {
        final offer = item['offer'] ?? {};
        final priceStr = (offer['price'] ?? item['typical_price_range']?[0] ?? '0')
            .toString()
            .replaceAll(RegExp(r'[^\d.]'), '');

        return Product(
          name: item['product_title']?.toString() ?? '',
          price: double.tryParse(priceStr) ?? 0.0,
          source: offer['store_name']?.toString() ?? 'Google Shopping',
          description: item['product_description']?.toString(),
          imageUrl: item['product_photos']?[0]?.toString(),
          productUrl: offer['offer_page_url']?.toString() ?? item['product_page_url']?.toString(),
          averageRating: (item['product_rating'] as num?)?.toDouble() ?? 0.0,
          numberOfRatings: item['product_num_reviews'] as int? ?? 0,
          brand: item['brand']?.toString(),
          category: item['product_category']?.toString(),
        );
      }).where((p) => p.name.isNotEmpty && p.price > 0).toList();
    } catch (_) {
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // 2. Amazon Product Data API
  //    Host: real-time-amazon-data.p.rapidapi.com
  // ──────────────────────────────────────────────
  Future<List<Product>> searchAmazon(
    String query, {
    int maxResults = 20,
    String country = 'IN',
    String? category,
  }) async {
    if (!isAvailable || !_connectivity.isConnected) return [];

    try {
      final params = {
        'query': query,
        'page': '1',
        'country': country,
        'sort_by': 'RELEVANCE',
      };
      if (category != null && category.isNotEmpty) {
        params['category_id'] = _mapAmazonCategory(category);
      }

      final uri = Uri.https(
        'real-time-amazon-data.p.rapidapi.com',
        '/search',
        params,
      );

      final response = await _httpClient
          .get(uri, headers: _headers('real-time-amazon-data.p.rapidapi.com'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseAmazonResults(response.body, maxResults, category);
      }
    } catch (_) {}
    return [];
  }

  List<Product> _parseAmazonResults(String body, int maxResults, String? category) {
    try {
      final json = jsonDecode(body);
      final products = json['data']?['products'] as List? ?? [];

      return products.take(maxResults).map<Product>((item) {
        final priceStr = (item['product_price'] ?? '0')
            .toString()
            .replaceAll(RegExp(r'[^\d.]'), '');

        return Product(
          name: item['product_title']?.toString() ?? '',
          price: double.tryParse(priceStr) ?? 0.0,
          source: 'Amazon',
          description: item['product_title']?.toString(),
          imageUrl: item['product_photo']?.toString(),
          productUrl: item['product_url']?.toString(),
          averageRating: double.tryParse(
                  item['product_star_rating']?.toString() ?? '0') ??
              0.0,
          numberOfRatings: int.tryParse((item['product_num_ratings'] ?? '0')
                  .toString()
                  .replaceAll(',', '')) ??
              0,
          brand: item['brand']?.toString(),
          category: category,
          sku: item['asin']?.toString(),
        );
      }).where((p) => p.name.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // 3. Walmart Product Search
  //    Host: walmart2.p.rapidapi.com
  // ──────────────────────────────────────────────
  Future<List<Product>> searchWalmart(
    String query, {
    int maxResults = 20,
  }) async {
    if (!isAvailable || !_connectivity.isConnected) return [];

    try {
      final uri = Uri.https(
        'walmart2.p.rapidapi.com',
        '/searchV2',
        {
          'query': query,
          'page': '1',
          'sort': 'best_match',
        },
      );

      final response = await _httpClient
          .get(uri, headers: _headers('walmart2.p.rapidapi.com'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseWalmartResults(response.body, maxResults);
      }
    } catch (_) {}
    return [];
  }

  List<Product> _parseWalmartResults(String body, int maxResults) {
    try {
      final json = jsonDecode(body);
      final items = json['responseData']?['results'] as List? ?? [];

      return items.take(maxResults).map<Product>((item) {
        return Product(
          name: item['title']?.toString() ?? '',
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          source: 'Walmart',
          description: item['shortDescription']?.toString(),
          imageUrl: item['image']?.toString(),
          productUrl: item['canonicalUrl'] != null
              ? 'https://www.walmart.com${item['canonicalUrl']}'
              : null,
          averageRating: (item['rating'] as num?)?.toDouble() ?? 0.0,
          numberOfRatings: item['numReviews'] as int? ?? 0,
          brand: item['brand']?.toString(),
          category: item['category']?.toString(),
        );
      }).where((p) => p.name.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // 4. eBay Product Search
  //    Host: ebay-search-result.p.rapidapi.com
  // ──────────────────────────────────────────────
  Future<List<Product>> searchEbay(
    String query, {
    int maxResults = 20,
  }) async {
    if (!isAvailable || !_connectivity.isConnected) return [];

    try {
      final uri = Uri.https(
        'ebay-search-result.p.rapidapi.com',
        '/search/$query',
        {'page': '1'},
      );

      final response = await _httpClient
          .get(uri, headers: _headers('ebay-search-result.p.rapidapi.com'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseEbayResults(response.body, maxResults);
      }
    } catch (_) {}
    return [];
  }

  List<Product> _parseEbayResults(String body, int maxResults) {
    try {
      final json = jsonDecode(body);
      final results = json['results'] as List? ?? [];

      return results.take(maxResults).map<Product>((item) {
        final priceStr = (item['price'] ?? '0')
            .toString()
            .replaceAll(RegExp(r'[^\d.]'), '');

        return Product(
          name: item['title']?.toString() ?? '',
          price: double.tryParse(priceStr) ?? 0.0,
          source: 'eBay',
          imageUrl: item['image']?.toString(),
          productUrl: item['url']?.toString(),
          averageRating: 0.0,
          numberOfRatings: 0,
        );
      }).where((p) => p.name.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // 5. Search ALL e-commerce via RapidAPI
  //    Aggregates Google Shopping + Amazon + Walmart + eBay
  // ──────────────────────────────────────────────
  Future<List<Product>> searchAllEcommerce(
    String query, {
    int maxResults = 50,
    String? category,
    String country = 'in',
  }) async {
    if (!isAvailable) {
      dev.log('RapidAPI NOT available: enableRapidApi=${_apiConfig.enableRapidApi} '
          'key=${_apiConfig.rapidApiKey.isNotEmpty ? "SET(${_apiConfig.rapidApiKey.length} chars)" : "EMPTY"}',
          name: 'RapidAPI');
      return [];
    }

    dev.log('RapidAPI searchAllEcommerce: query="$query" country=$country '
        'category=$category maxResults=$maxResults', name: 'RapidAPI');

    final futures = <Future<List<Product>>>[
      searchGoogleShopping(query,
          maxResults: maxResults ~/ 4, country: country, category: category),
      searchAmazon(query,
          maxResults: maxResults ~/ 4,
          country: country.toUpperCase(),
          category: category),
      searchWalmart(query, maxResults: maxResults ~/ 4),
      searchEbay(query, maxResults: maxResults ~/ 4),
    ];

    final results = await Future.wait(futures);
    final allProducts = <Product>[];
    for (final list in results) {
      allProducts.addAll(list);
    }

    // Deduplicate by name similarity
    final seen = <String>{};
    final deduped = <Product>[];
    for (final p in allProducts) {
      final key = p.name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      if (key.length > 10) {
        final shortKey = key.substring(0, 10);
        if (!seen.contains(shortKey)) {
          seen.add(shortKey);
          deduped.add(p);
        }
      } else {
        if (!seen.contains(key)) {
          seen.add(key);
          deduped.add(p);
        }
      }
    }

    return deduped.take(maxResults).toList();
  }

  // ──── Category Mapping ────
  /// E-commerce category IDs for Amazon search
  static final _amazonCategories = <String, String>{
    'Electronics': 'aps',
    'Smartphones': 'mobile',
    'Laptops': 'computers',
    'Television': 'electronics',
    'Audio': 'electronics',
    'Cameras': 'electronics',
    'Tablets': 'computers',
    'Fashion': 'fashion',
    'Beauty': 'beauty',
    'Grocery': 'grocery',
    'Home': 'garden',
    'Books': 'stripbooks',
    'Toys': 'toys',
    'Sports': 'sporting',
    'Automotive': 'automotive',
    'Health': 'hpc',
    'Baby': 'baby',
    'Pet Supplies': 'pets',
    'Office': 'office-products',
    'Tools': 'tools',
    'Garden': 'garden',
    'Jewelry': 'jewelry',
    'Watches': 'watches',
    'Shoes': 'shoes',
    'Luggage': 'luggage',
    'Musical Instruments': 'mi',
    'Software': 'software',
    'Video Games': 'videogames',
  };

  String _mapAmazonCategory(String category) {
    return _amazonCategories[category] ?? 'aps';
  }

  /// All supported e-commerce categories for browsing
  static const supportedCategories = [
    'Electronics',
    'Smartphones',
    'Laptops',
    'Television',
    'Audio',
    'Cameras',
    'Tablets',
    'Fashion',
    'Beauty',
    'Grocery',
    'Home',
    'Books',
    'Toys',
    'Sports',
    'Automotive',
    'Health',
    'Baby',
    'Pet Supplies',
    'Office',
    'Tools',
    'Garden',
    'Jewelry',
    'Watches',
    'Shoes',
    'Luggage',
    'Musical Instruments',
    'Software',
    'Video Games',
  ];
}
