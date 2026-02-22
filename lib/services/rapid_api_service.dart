import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'connectivity_service.dart';

/// RapidAPI multi-platform e-commerce search service.
///
/// Uses a single RapidAPI key (TB_RAPIDAPI_KEY) with multiple host endpoints:
/// - Real-Time Product Search (Google Shopping aggregation)
/// - Real-Time Amazon Data
/// - eBay Average Selling Price (confirmed working)
class RapidApiService {
  final http.Client _httpClient;
  final ApiConfiguration _apiConfig;
  final ConnectivityService _connectivity;

  RapidApiService(this._httpClient, this._apiConfig, this._connectivity);

  bool get isAvailable =>
      _apiConfig.enableRapidApi && _apiConfig.rapidApiKey.isNotEmpty;

  Map<String, String> _getHeaders(String host) => {
        'X-RapidAPI-Key': _apiConfig.rapidApiKey,
        'X-RapidAPI-Host': host,
      };

  // ──────────────────────────────────────────────
  // 1. Real-Time Product Search (Google Shopping)
  //    Host: real-time-product-search.p.rapidapi.com
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
        },
      );

      print('[RapidAPI] GoogleShopping GET: $uri');

      final response = await _httpClient
          .get(uri, headers: _getHeaders('real-time-product-search.p.rapidapi.com'))
          .timeout(const Duration(seconds: 15));

      print('[RapidAPI] GoogleShopping: status=${response.statusCode} bodyLen=${response.body.length}');

      if (response.statusCode == 200) {
        final results = _parseGoogleShoppingResults(response.body);
        print('[RapidAPI] GoogleShopping: parsed ${results.length} products');
        return results;
      } else {
        final preview = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        print('[RapidAPI] GoogleShopping ERROR: $preview');
      }
    } catch (e) {
      print('[RapidAPI] GoogleShopping EXCEPTION: $e');
    }
    return [];
  }

  List<Product> _parseGoogleShoppingResults(String body) {
    try {
      final json = jsonDecode(body);
      final data = json['data'] as List? ?? [];

      return data.map<Product>((item) {
        final offer = item['offer'] ?? {};
        final priceStr =
            (offer['price'] ?? item['typical_price_range']?[0] ?? '0')
                .toString()
                .replaceAll(RegExp(r'[^\d.]'), '');

        return Product(
          name: item['product_title']?.toString() ?? '',
          price: double.tryParse(priceStr) ?? 0.0,
          source: offer['store_name']?.toString() ?? 'Google Shopping',
          description: item['product_description']?.toString(),
          imageUrl: item['product_photos']?[0]?.toString(),
          productUrl: offer['offer_page_url']?.toString() ??
              item['product_page_url']?.toString(),
          averageRating:
              (item['product_rating'] as num?)?.toDouble() ?? 0.0,
          numberOfRatings: item['product_num_reviews'] as int? ?? 0,
          brand: item['brand']?.toString(),
          category: item['product_category']?.toString(),
        );
      }).where((p) => p.name.isNotEmpty && p.price > 0).toList();
    } catch (e) {
      print('[RapidAPI] GoogleShopping parse error: $e');
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

      print('[RapidAPI] Amazon GET: query="$query" country=$country');

      final response = await _httpClient
          .get(uri, headers: _getHeaders('real-time-amazon-data.p.rapidapi.com'))
          .timeout(const Duration(seconds: 15));

      print('[RapidAPI] Amazon: status=${response.statusCode} bodyLen=${response.body.length}');

      if (response.statusCode == 200) {
        final results = _parseAmazonResults(response.body, maxResults, category);
        print('[RapidAPI] Amazon: parsed ${results.length} products');
        return results;
      } else {
        final preview = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        print('[RapidAPI] Amazon ERROR: $preview');
      }
    } catch (e) {
      print('[RapidAPI] Amazon EXCEPTION: $e');
    }
    return [];
  }

  List<Product> _parseAmazonResults(
      String body, int maxResults, String? category) {
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
          numberOfRatings: int.tryParse(
                  (item['product_num_ratings'] ?? '0')
                      .toString()
                      .replaceAll(',', '')) ??
              0,
          brand: item['brand']?.toString(),
          category: category,
          sku: item['asin']?.toString(),
        );
      }).where((p) => p.name.isNotEmpty).toList();
    } catch (e) {
      print('[RapidAPI] Amazon parse error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // 3. eBay Average Selling Price (CONFIRMED WORKING)
  //    Host: ebay-average-selling-price.p.rapidapi.com
  //    POST /findCompletedItems
  // ──────────────────────────────────────────────
  Future<List<Product>> searchEbay(
    String query, {
    int maxResults = 20,
  }) async {
    if (!isAvailable || !_connectivity.isConnected) return [];

    try {
      final uri = Uri.https(
        'ebay-average-selling-price.p.rapidapi.com',
        '/findCompletedItems',
      );

      final requestBody = jsonEncode({
        'keywords': query,
        'max_search_results': maxResults.toString(),
        'remove_outliers': 'true',
        'site_id': '0',
      });

      final headers = {
        ..._getHeaders('ebay-average-selling-price.p.rapidapi.com'),
        'Content-Type': 'application/json',
      };

      print('[RapidAPI] eBay POST: query="$query"');

      final response = await _httpClient
          .post(uri, headers: headers, body: requestBody)
          .timeout(const Duration(seconds: 15));

      print('[RapidAPI] eBay: status=${response.statusCode} bodyLen=${response.body.length}');

      if (response.statusCode == 200) {
        final results = _parseEbayResults(response.body, maxResults);
        print('[RapidAPI] eBay: parsed ${results.length} products');
        return results;
      } else {
        final preview = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        print('[RapidAPI] eBay ERROR: $preview');
      }
    } catch (e) {
      print('[RapidAPI] eBay EXCEPTION: $e');
    }
    return [];
  }

  List<Product> _parseEbayResults(String body, int maxResults) {
    try {
      final json = jsonDecode(body);

      final avgPrice =
          (json['average_price'] as num?)?.toDouble() ?? 0.0;
      final medianPrice =
          (json['median_price'] as num?)?.toDouble() ?? 0.0;
      final products = json['products'] as List? ?? [];

      print('[RapidAPI] eBay parsed: ${products.length} products, '
          'avg=\$${avgPrice.toStringAsFixed(2)}, '
          'median=\$${medianPrice.toStringAsFixed(2)}');

      return products.take(maxResults).map<Product>((item) {
        return Product(
          name: item['title']?.toString() ?? '',
          price: (item['price'] as num?)?.toDouble() ?? avgPrice,
          source: 'eBay',
          imageUrl: item['image_url']?.toString(),
          productUrl: item['url']?.toString(),
          averageRating: 0.0,
          numberOfRatings: 0,
          category: item['category']?.toString(),
        );
      }).where((p) => p.name.isNotEmpty).toList();
    } catch (e) {
      print('[RapidAPI] eBay parse error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // Master search — aggregates all endpoints
  // ──────────────────────────────────────────────
  Future<List<Product>> searchAllEcommerce(
    String query, {
    int maxResults = 50,
    String? category,
    String country = 'in',
  }) async {
    if (!isAvailable) {
      print('[RapidAPI] NOT available: '
          'enableRapidApi=${_apiConfig.enableRapidApi} '
          'keySet=${_apiConfig.rapidApiKey.isNotEmpty}');
      return [];
    }

    print('[RapidAPI] === searchAllEcommerce START === '
        'query="$query" country=$country '
        'keyPrefix=${_apiConfig.rapidApiKey.length > 8 ? _apiConfig.rapidApiKey.substring(0, 8) : "short"}...');

    final futures = <Future<List<Product>>>[
      searchGoogleShopping(query,
          maxResults: maxResults ~/ 3, country: country, category: category),
      searchAmazon(query,
          maxResults: maxResults ~/ 3,
          country: country.toUpperCase(),
          category: category),
      searchEbay(query, maxResults: maxResults ~/ 3),
    ];

    final results = await Future.wait(futures);
    final allProducts = <Product>[];
    for (final list in results) {
      allProducts.addAll(list);
    }

    print('[RapidAPI] Total raw results: ${allProducts.length}');

    // Deduplicate by name prefix
    final seen = <String>{};
    final deduped = <Product>[];
    for (final p in allProducts) {
      final key = p.name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      final lookupKey = key.length > 10 ? key.substring(0, 10) : key;
      if (!seen.contains(lookupKey)) {
        seen.add(lookupKey);
        deduped.add(p);
      }
    }

    print('[RapidAPI] === searchAllEcommerce END === ${deduped.length} unique products');
    return deduped.take(maxResults).toList();
  }

  // ──── Helpers ────
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

  String _mapAmazonCategory(String category) =>
      _amazonCategories[category] ?? 'aps';

  static const supportedCategories = [
    'Electronics', 'Smartphones', 'Laptops', 'Television', 'Audio',
    'Cameras', 'Tablets', 'Fashion', 'Beauty', 'Grocery', 'Home',
    'Books', 'Toys', 'Sports', 'Automotive', 'Health', 'Baby',
    'Pet Supplies', 'Office', 'Tools', 'Garden', 'Jewelry', 'Watches',
    'Shoes', 'Luggage', 'Musical Instruments', 'Software', 'Video Games',
  ];
}
