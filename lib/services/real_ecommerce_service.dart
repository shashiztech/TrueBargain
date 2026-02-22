import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'connectivity_service.dart';

/// Per-platform search — NO MOCK DATA.
/// Returns empty list if real API key is not configured for a platform.
/// All real product data comes via RapidAPI or direct platform APIs.
class RealEcommerceService {
  final http.Client _httpClient;
  final ApiConfiguration _apiConfig;
  final ConnectivityService _connectivity;

  RealEcommerceService(this._httpClient, this._apiConfig, this._connectivity);

  // All platform methods return EMPTY if no real API key is configured.
  // Mock data generation has been completely removed.

  Future<List<Product>> searchAmazonProducts(String query,
      {int maxResults = 20}) async {
    if (!_connectivity.isConnected) return [];
    if (_apiConfig.amazonApiKey.isEmpty) return []; // No key → no results
    return _searchAmazonReal(query, maxResults);
  }

  Future<List<Product>> searchWalmartProducts(String query,
      {int maxResults = 20}) async {
    if (!_connectivity.isConnected) return [];
    if (_apiConfig.walmartApiKey.isEmpty) return [];
    return _searchWalmartReal(query, maxResults);
  }

  Future<List<Product>> searchBestBuyProducts(String query,
      {int maxResults = 20}) async {
    if (!_connectivity.isConnected) return [];
    if (_apiConfig.bestBuyApiKey.isEmpty) return [];
    return _searchBestBuyReal(query, maxResults);
  }

  Future<List<Product>> searchEbayProducts(String query,
      {int maxResults = 20}) async {
    if (!_connectivity.isConnected) return [];
    if (_apiConfig.ebayApiKey.isEmpty) return [];
    return _searchEbayReal(query, maxResults);
  }

  Future<List<Product>> searchFlipkartProducts(String query,
      {int maxResults = 20}) async {
    if (!_connectivity.isConnected) return [];
    if (_apiConfig.flipkartApiKey.isEmpty) return [];
    return _searchFlipkartReal(query, maxResults);
  }

  Future<List<Product>> searchMyntraProducts(String query,
      {int maxResults = 20}) async {
    if (!_connectivity.isConnected) return [];
    if (_apiConfig.myntraApiKey.isEmpty) return [];
    return []; // TODO: Implement real Myntra API
  }

  Future<List<Product>> searchNykaaProducts(String query,
      {int maxResults = 20}) async {
    return []; // TODO: Implement real Nykaa API
  }

  Future<List<Product>> searchMeeshoProducts(String query,
      {int maxResults = 20}) async {
    return []; // TODO: Implement real Meesho API
  }

  Future<List<Product>> searchCromaProducts(String query,
      {int maxResults = 20}) async {
    if (!_connectivity.isConnected) return [];
    if (_apiConfig.cromaApiKey.isEmpty) return [];
    return []; // TODO: Implement real Croma API
  }

  Future<List<Product>> searchBlinkitProducts(String query,
      {int maxResults = 20}) async {
    return []; // TODO: Implement real Blinkit API
  }

  Future<List<Product>> searchSwiggyProducts(String query,
      {int maxResults = 20}) async {
    return []; // TODO: Implement real Swiggy API
  }

  bool isIndianPlatform(String? source) {
    if (source == null) return false;
    final s = source.toLowerCase();
    return ['flipkart', 'myntra', 'nykaa', 'meesho', 'croma', 'blinkit',
            'swiggy', 'bigbasket', 'jiomart', 'zepto']
        .any((p) => s.contains(p));
  }

  // ──── Real API stubs — return empty, NOT mock data ────
  Future<List<Product>> _searchAmazonReal(String query, int max) async {
    return _executeWithRetry(() async {
      // TODO: Implement Amazon PA-API 5.0
      return <Product>[];
    });
  }

  Future<List<Product>> _searchWalmartReal(String query, int max) async {
    return _executeWithRetry(() async {
      // TODO: Implement Walmart API
      return <Product>[];
    });
  }

  Future<List<Product>> _searchBestBuyReal(String query, int max) async {
    return _executeWithRetry(() async {
      // TODO: Implement Best Buy API
      return <Product>[];
    });
  }

  Future<List<Product>> _searchEbayReal(String query, int max) async {
    return _executeWithRetry(() async {
      // TODO: Implement eBay API
      return <Product>[];
    });
  }

  Future<List<Product>> _searchFlipkartReal(String query, int max) async {
    return _executeWithRetry(() async {
      // TODO: Implement Flipkart Affiliate API
      return <Product>[];
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
}
