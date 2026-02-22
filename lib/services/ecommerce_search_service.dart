import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'real_ecommerce_service.dart';
import 'product_data_service.dart';
import 'rapid_api_service.dart';
import 'connectivity_service.dart';

/// Multi-platform search orchestration — NO MOCK DATA.
/// All results come from real APIs (RapidAPI or direct platform APIs).
/// Returns empty result with error message if offline or no API configured.
class EcommerceSearchService {
  final http.Client _httpClient;
  final ProductDataService _productDataService;
  final RealEcommerceService _realEcommerceService;
  final ApiConfiguration _apiConfig;
  RapidApiService? _rapidApiService;
  ConnectivityService? _connectivityService;

  EcommerceSearchService(
    this._httpClient,
    this._productDataService,
    this._realEcommerceService,
    this._apiConfig,
  );

  /// Attach RapidAPI service for real product data
  void setRapidApiService(RapidApiService service) {
    _rapidApiService = service;
  }

  /// Attach connectivity service for offline detection
  void setConnectivityService(ConnectivityService service) {
    _connectivityService = service;
  }

  /// Search all platforms — REAL DATA ONLY, no mock/dummy results.
  /// Returns empty SearchResult if offline or no API key configured.
  Future<SearchResult> searchAllPlatforms(SearchRequest request) async {
    final stopwatch = Stopwatch()..start();

    // Check connectivity first
    if (_connectivityService != null && !_connectivityService!.isConnected) {
      stopwatch.stop();
      print('[Search] OFFLINE — cannot search');
      return SearchResult(
        products: [],
        totalCount: 0,
        query: request.query,
        searchDuration: stopwatch.elapsed,
        sourceCounts: {},
      );
    }

    final useRapidApi =
        _rapidApiService != null && _rapidApiService!.isAvailable;

    print('[Search] query="${request.query}" useRapidApi=$useRapidApi '
        'rapidApiKey=${_apiConfig.rapidApiKey.isNotEmpty ? "SET(${_apiConfig.rapidApiKey.length}chars)" : "EMPTY"} '
        'enableRapidApi=${_apiConfig.enableRapidApi}');

    final allProducts = <Product>[];
    final sourceCounts = <EcommerceSource, int>{};
    final futures = <Future<List<Product>>>[];

    // ONLY use RapidAPI for real product data — no mock generators
    if (useRapidApi) {
      futures.add(_searchRapidApi(request));
    } else {
      print('[Search] WARNING: No RapidAPI key available. '
          'Configure TB_RAPIDAPI_KEY in Firebase Remote Config or Settings.');
    }

    final results = await Future.wait(futures);
    for (final products in results) {
      allProducts.addAll(products);
    }

    // Apply filters
    var filtered = _applyFilters(allProducts, request);

    // Apply sort
    filtered = _applySort(filtered, request.sortOrder);

    // Limit results
    if (filtered.length > request.maxResults) {
      filtered = filtered.sublist(0, request.maxResults);
    }

    // Count sources
    for (final p in filtered) {
      final src = _mapSource(p.source);
      sourceCounts[src] = (sourceCounts[src] ?? 0) + 1;
    }

    stopwatch.stop();

    return SearchResult(
      products: filtered,
      totalCount: filtered.length,
      query: request.query,
      searchDuration: stopwatch.elapsed,
      sourceCounts: sourceCounts,
    );
  }

  Future<List<Product>> _searchPlatform(
      String name, SearchRequest request, EcommerceSource source) async {
    try {
      switch (name) {
        case 'Amazon':
          return await _realEcommerceService.searchAmazonProducts(
              request.query,
              maxResults: request.maxResults ~/ 5);
        case 'Flipkart':
          return await _realEcommerceService.searchFlipkartProducts(
              request.query,
              maxResults: request.maxResults ~/ 5);
        case 'Walmart':
          return await _realEcommerceService.searchWalmartProducts(
              request.query,
              maxResults: request.maxResults ~/ 5);
        case 'Best Buy':
          return await _realEcommerceService.searchBestBuyProducts(
              request.query,
              maxResults: request.maxResults ~/ 5);
        case 'Myntra':
          return await _realEcommerceService.searchMyntraProducts(
              request.query,
              maxResults: request.maxResults ~/ 5);
        case 'Croma':
          return await _realEcommerceService.searchCromaProducts(
              request.query,
              maxResults: request.maxResults ~/ 5);
        case 'eBay':
          return await _realEcommerceService.searchEbayProducts(
              request.query,
              maxResults: request.maxResults ~/ 5);
        default:
          return [];
      }
    } catch (_) {
      return [];
    }
  }

  /// Search via RapidAPI aggregated endpoints
  Future<List<Product>> _searchRapidApi(SearchRequest request) async {
    try {
      return await _rapidApiService!.searchAllEcommerce(
        request.query,
        maxResults: request.maxResults ~/ 3,
        category: request.category,
      );
    } catch (_) {
      return [];
    }
  }

  List<Product> _applyFilters(List<Product> products, SearchRequest req) {
    return products.where((p) {
      if (req.minPrice != null && p.price < req.minPrice!) return false;
      if (req.maxPrice != null && p.price > req.maxPrice!) return false;
      if (req.minRating != null && p.averageRating < req.minRating!) {
        return false;
      }
      if (req.category != null &&
          req.category!.isNotEmpty &&
          p.category?.toLowerCase() != req.category!.toLowerCase()) {
        return false;
      }
      if (req.brand != null &&
          req.brand!.isNotEmpty &&
          p.brand?.toLowerCase() != req.brand!.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Product> _applySort(List<Product> products, SearchSortOrder order) {
    switch (order) {
      case SearchSortOrder.priceLowToHigh:
        products.sort((a, b) => a.price.compareTo(b.price));
      case SearchSortOrder.priceHighToLow:
        products.sort((a, b) => b.price.compareTo(a.price));
      case SearchSortOrder.ratingHighToLow:
        products.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      case SearchSortOrder.mostReviews:
        products.sort(
            (a, b) => b.numberOfRatings.compareTo(a.numberOfRatings));
      case SearchSortOrder.newest:
        products.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      case SearchSortOrder.relevance:
        break; // Keep original order
    }
    return products;
  }

  EcommerceSource _mapSource(String? source) {
    if (source == null) return EcommerceSource.all;
    final s = source.toLowerCase();
    if (s.contains('amazon')) return EcommerceSource.amazon;
    if (s.contains('flipkart')) return EcommerceSource.flipkart;
    if (s.contains('walmart')) return EcommerceSource.walmart;
    if (s.contains('best buy')) return EcommerceSource.bestBuy;
    if (s.contains('myntra')) return EcommerceSource.myntra;
    if (s.contains('croma')) return EcommerceSource.croma;
    if (s.contains('ebay')) return EcommerceSource.ebay;
    if (s.contains('target')) return EcommerceSource.target;
    return EcommerceSource.all;
  }
}
