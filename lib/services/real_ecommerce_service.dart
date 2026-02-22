import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'connectivity_service.dart';

/// Per-platform search with real API + mock fallback
class RealEcommerceService {
  final http.Client _httpClient;
  final ApiConfiguration _apiConfig;
  final ConnectivityService _connectivity;

  RealEcommerceService(this._httpClient, this._apiConfig, this._connectivity);

  // ──── Global platforms ────
  Future<List<Product>> searchAmazonProducts(String query,
      {int maxResults = 20}) async {
    if (_apiConfig.useRealApis && _apiConfig.amazonApiKey.isNotEmpty) {
      return _searchAmazonReal(query, maxResults);
    }
    return _generateMockProducts(query, 'Amazon', maxResults);
  }

  Future<List<Product>> searchWalmartProducts(String query,
      {int maxResults = 20}) async {
    if (_apiConfig.useRealApis && _apiConfig.walmartApiKey.isNotEmpty) {
      return _searchWalmartReal(query, maxResults);
    }
    return _generateMockProducts(query, 'Walmart', maxResults);
  }

  Future<List<Product>> searchBestBuyProducts(String query,
      {int maxResults = 20}) async {
    if (_apiConfig.useRealApis && _apiConfig.bestBuyApiKey.isNotEmpty) {
      return _searchBestBuyReal(query, maxResults);
    }
    return _generateMockProducts(query, 'Best Buy', maxResults);
  }

  Future<List<Product>> searchEbayProducts(String query,
      {int maxResults = 20}) async {
    if (_apiConfig.useRealApis && _apiConfig.ebayApiKey.isNotEmpty) {
      return _searchEbayReal(query, maxResults);
    }
    return _generateMockProducts(query, 'eBay', maxResults);
  }

  // ──── Indian market ────
  Future<List<Product>> searchFlipkartProducts(String query,
      {int maxResults = 20}) async {
    if (_apiConfig.useRealApis && _apiConfig.flipkartApiKey.isNotEmpty) {
      return _searchFlipkartReal(query, maxResults);
    }
    return _generateMockProducts(query, 'Flipkart', maxResults,
        currency: 'INR');
  }

  Future<List<Product>> searchMyntraProducts(String query,
      {int maxResults = 20}) async {
    return _generateMockProducts(query, 'Myntra', maxResults,
        currency: 'INR', category: 'Fashion');
  }

  Future<List<Product>> searchNykaaProducts(String query,
      {int maxResults = 20}) async {
    return _generateMockProducts(query, 'Nykaa', maxResults,
        currency: 'INR', category: 'Beauty');
  }

  Future<List<Product>> searchMeeshoProducts(String query,
      {int maxResults = 20}) async {
    return _generateMockProducts(query, 'Meesho', maxResults,
        currency: 'INR');
  }

  Future<List<Product>> searchCromaProducts(String query,
      {int maxResults = 20}) async {
    return _generateMockProducts(query, 'Croma', maxResults,
        currency: 'INR', category: 'Electronics');
  }

  Future<List<Product>> searchBlinkitProducts(String query,
      {int maxResults = 20}) async {
    return _generateMockProducts(query, 'Blinkit', maxResults,
        currency: 'INR', category: 'Grocery');
  }

  Future<List<Product>> searchSwiggyProducts(String query,
      {int maxResults = 20}) async {
    return _generateMockProducts(query, 'Swiggy Instamart', maxResults,
        currency: 'INR', category: 'Grocery');
  }

  // ──── Affiliate URL building ────
  String getProductLink(Product product) {
    if (!_apiConfig.enableAffiliateLinks) return product.productUrl ?? '';

    final source = product.source?.toLowerCase() ?? '';
    final url = product.productUrl ?? '';

    if (source.contains('amazon') && _apiConfig.amazonAssociateTag.isNotEmpty) {
      return '$url${url.contains('?') ? '&' : '?'}tag=${_apiConfig.amazonAssociateTag}';
    }
    if (source.contains('flipkart') &&
        _apiConfig.flipkartAffiliateId.isNotEmpty) {
      return '$url${url.contains('?') ? '&' : '?'}affid=${_apiConfig.flipkartAffiliateId}';
    }
    return url;
  }

  bool isIndianPlatform(String? source) {
    if (source == null) return false;
    final s = source.toLowerCase();
    return ['flipkart', 'myntra', 'nykaa', 'meesho', 'croma', 'blinkit',
            'swiggy', 'bigbasket', 'jiomart', 'zepto']
        .any((p) => s.contains(p));
  }

  // ──── Real API stubs (implement with actual API calls) ────
  Future<List<Product>> _searchAmazonReal(String query, int max) async {
    return _executeWithRetry(() async {
      // TODO: Implement PA-API 5.0
      // POST https://webservices.amazon.in/paapi5/searchitems
      return _generateMockProducts(query, 'Amazon', max);
    });
  }

  Future<List<Product>> _searchWalmartReal(String query, int max) async {
    return _executeWithRetry(() async {
      return _generateMockProducts(query, 'Walmart', max);
    });
  }

  Future<List<Product>> _searchBestBuyReal(String query, int max) async {
    return _executeWithRetry(() async {
      return _generateMockProducts(query, 'Best Buy', max);
    });
  }

  Future<List<Product>> _searchEbayReal(String query, int max) async {
    return _executeWithRetry(() async {
      return _generateMockProducts(query, 'eBay', max);
    });
  }

  Future<List<Product>> _searchFlipkartReal(String query, int max) async {
    return _executeWithRetry(() async {
      return _generateMockProducts(query, 'Flipkart', max, currency: 'INR');
    });
  }

  // ──── Retry logic ────
  Future<List<Product>> _executeWithRetry(
      Future<List<Product>> Function() action) async {
    if (!_connectivity.isConnected) return [];

    for (int attempt = 0;
        attempt < _apiConfig.maxRetryAttempts;
        attempt++) {
      try {
        return await action();
      } catch (e) {
        if (attempt == _apiConfig.maxRetryAttempts - 1) return [];
        await Future.delayed(Duration(
            milliseconds:
                _apiConfig.retryDelayMilliseconds * (1 << attempt)));
      }
    }
    return [];
  }

  // ──── Mock data generation ────
  List<Product> _generateMockProducts(
      String query, String source, int maxResults,
      {String currency = 'USD', String? category}) {
    final random = Random();
    final brands = ['Samsung', 'Apple', 'Sony', 'LG', 'OnePlus', 'Xiaomi'];
    final priceMultiplier = currency == 'INR' ? 80.0 : 1.0;

    return List.generate(min(maxResults, 10), (i) {
      final brand = brands[random.nextInt(brands.length)];
      final basePrice = (random.nextDouble() * 900 + 100) * priceMultiplier;

      return Product(
        name: '$brand $query ${['Pro', 'Ultra', 'Max', 'Lite', 'Plus'][random.nextInt(5)]} ${i + 1}',
        brand: brand,
        category: category ?? 'Electronics',
        price: double.parse(basePrice.toStringAsFixed(2)),
        averageRating: (random.nextDouble() * 2 + 3),
        numberOfRatings: random.nextInt(5000) + 100,
        source: source,
        description: 'High-quality $query from $brand. Available on $source.',
        imageUrl: 'https://via.placeholder.com/150?text=${Uri.encodeComponent(brand)}',
        productUrl: 'https://www.$source.com/dp/${random.nextInt(999999)}',
        sku: '${source.toUpperCase().replaceAll(' ', '')}-${random.nextInt(99999)}',
      );
    });
  }
}
