import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Full multi-source search with location, preferences persistence, and price tracking
class HomeProvider extends ChangeNotifier {
  final EcommerceSearchService _searchService;
  final ProductGroupingService _groupingService;
  final AIRecommendationService _aiRecommendation;
  final CacheService _cacheService;
  final AnalyticsService _analyticsService;
  final ConnectivityService _connectivityService;
  final PriceHistoryService _priceHistoryService;

  HomeProvider({
    required EcommerceSearchService searchService,
    required ProductGroupingService groupingService,
    required AIRecommendationService aiRecommendation,
    required CacheService cacheService,
    required AnalyticsService analyticsService,
    required ConnectivityService connectivityService,
    required PriceHistoryService priceHistoryService,
  })  : _searchService = searchService,
        _groupingService = groupingService,
        _aiRecommendation = aiRecommendation,
        _cacheService = cacheService,
        _analyticsService = analyticsService,
        _connectivityService = connectivityService,
        _priceHistoryService = priceHistoryService {
    _loadPreferences();
  }

  // ──── State ────
  List<Product> _searchResults = [];
  List<ProductGroupViewModel> _groupedResults = [];
  String _query = '';
  bool _isLoading = false;
  bool _isGroupedView = false; // Default to flat view (shows thumbnails)
  bool _isNlpMode = false;
  String? _errorMessage;
  String? _aiRecommendation2;
  SearchSortOrder _sortOrder = SearchSortOrder.relevance;
  EcommerceSource _sourceFilter = EcommerceSource.all;

  // Location
  String _searchCountry = 'in';
  String _searchCountryName = 'India';
  bool _locationSet = false;
  bool _showLocationPrompt = true;

  // Recent searches
  List<String> _recentSearches = [];

  // Price changes map: productIdentifier → {previousPrice, priceChange}
  final Map<String, double> _previousPrices = {};

  // Cache
  final Map<String, List<Product>> _memoryCache = {};
  Timer? _debounceTimer;

  // ──── Getters ────
  List<Product> get searchResults => _searchResults;
  List<ProductGroupViewModel> get groupedResults => _groupedResults;
  String get query => _query;
  bool get isLoading => _isLoading;
  bool get isGroupedView => _isGroupedView;
  bool get isNlpMode => _isNlpMode;
  String? get errorMessage => _errorMessage;
  String? get aiRecommendationText => _aiRecommendation2;
  SearchSortOrder get sortOrder => _sortOrder;
  EcommerceSource get sourceFilter => _sourceFilter;
  bool get isConnected => _connectivityService.isConnected;
  bool get hasResults => _searchResults.isNotEmpty;
  String get searchCountry => _searchCountry;
  String get searchCountryName => _searchCountryName;
  bool get locationSet => _locationSet;
  bool get showLocationPrompt => _showLocationPrompt;
  List<String> get recentSearches => _recentSearches;

  /// Get price change text for a product (e.g., "↓ ₹500 since last search")
  String? getPriceChangeText(Product product) {
    final key = '${product.name}|${product.source}';
    final prev = _previousPrices[key];
    if (prev == null || prev == 0) return null;

    final diff = product.price - prev;
    if (diff.abs() < 1) return null;

    if (diff < 0) {
      return '↓ ₹${diff.abs().toStringAsFixed(0)} since last search';
    } else {
      return '↑ ₹${diff.toStringAsFixed(0)} since last search';
    }
  }

  bool isPriceDrop(Product product) {
    final key = '${product.name}|${product.source}';
    final prev = _previousPrices[key];
    return prev != null && product.price < prev;
  }

  // ──── Supported countries ────
  static const countries = {
    'in': 'India',
    'us': 'United States',
    'gb': 'United Kingdom',
    'ca': 'Canada',
    'au': 'Australia',
    'de': 'Germany',
    'fr': 'France',
    'jp': 'Japan',
    'br': 'Brazil',
    'ae': 'UAE',
    'sg': 'Singapore',
  };

  // ──── Load/Save preferences ────
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Sort order
      final sortIdx = prefs.getInt('pref_sort_order') ?? 0;
      if (sortIdx < SearchSortOrder.values.length) {
        _sortOrder = SearchSortOrder.values[sortIdx];
      }

      // View mode
      _isGroupedView = prefs.getBool('pref_grouped_view') ?? false;

      // NLP mode
      _isNlpMode = prefs.getBool('pref_nlp_mode') ?? false;

      // Location
      _searchCountry = prefs.getString('pref_country') ?? 'in';
      _searchCountryName = countries[_searchCountry] ?? 'India';
      _locationSet = prefs.getBool('pref_location_set') ?? false;
      _showLocationPrompt = !_locationSet;

      // Recent searches
      _recentSearches = prefs.getStringList('pref_recent_searches') ?? [];

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pref_sort_order', _sortOrder.index);
      await prefs.setBool('pref_grouped_view', _isGroupedView);
      await prefs.setBool('pref_nlp_mode', _isNlpMode);
      await prefs.setString('pref_country', _searchCountry);
      await prefs.setBool('pref_location_set', _locationSet);
      await prefs.setStringList('pref_recent_searches', _recentSearches);
    } catch (_) {}
  }

  Future<void> _addRecentSearch(String query) async {
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    await _savePreferences();
  }

  // ──── Location ────
  void setCountry(String code) {
    _searchCountry = code;
    _searchCountryName = countries[code] ?? code.toUpperCase();
    _locationSet = true;
    _showLocationPrompt = false;
    _memoryCache.clear(); // Clear cache for new country
    _savePreferences();
    notifyListeners();
  }

  void dismissLocationPrompt() {
    _showLocationPrompt = false;
    notifyListeners();
  }

  // ──── Setters ────
  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSortOrder(SearchSortOrder order) {
    _sortOrder = order;
    _savePreferences();
    notifyListeners();
    if (_searchResults.isNotEmpty) search();
  }

  void setSourceFilter(EcommerceSource source) {
    _sourceFilter = source;
    notifyListeners();
    if (_searchResults.isNotEmpty) search();
  }

  void toggleGroupedView() {
    _isGroupedView = !_isGroupedView;
    _savePreferences();
    notifyListeners();
  }

  void toggleNlpMode() {
    _isNlpMode = !_isNlpMode;
    _savePreferences();
    notifyListeners();
  }

  /// Debounced search (500ms)
  void searchDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      search();
    });
  }

  /// Execute search
  Future<void> search() async {
    if (_query.trim().isEmpty) return;

    // Check connectivity
    if (!_connectivityService.isConnected) {
      _errorMessage =
          'You are offline. Please connect to the Internet to search for products.';
      _searchResults = [];
      _groupedResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Save to recent searches
      await _addRecentSearch(_query);

      // Check memory cache
      final cacheKey =
          '${_query}_${_sourceFilter.name}_${_sortOrder.name}_$_searchCountry';
      if (_memoryCache.containsKey(cacheKey)) {
        _searchResults = _memoryCache[cacheKey]!;
        await _groupResults();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check file cache
      final fileCacheKey =
          _cacheService.buildCacheKey(_query, _searchCountry, _sortOrder.name);
      final cached = await _cacheService.getCachedSearch(
          fileCacheKey, const Duration(minutes: 5));
      if (cached != null && cached.isNotEmpty) {
        _searchResults = cached;
        _memoryCache[cacheKey] = cached;
        await _groupResults();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Build request
      SearchRequest request;
      if (_isNlpMode) {
        request = await _aiRecommendation.parseNaturalLanguageQuery(_query);
        request = request.copyWith(
          source: _sourceFilter,
          sortOrder: _sortOrder,
        );
      } else {
        request = SearchRequest(
          query: _query,
          sortOrder: _sortOrder,
          source: _sourceFilter,
        );
      }

      // Execute search
      final stopwatch = Stopwatch()..start();
      final result = await _searchService.searchAllPlatforms(request);
      stopwatch.stop();

      // Load previous prices for comparison
      await _loadPreviousPrices(result.products);

      _searchResults = result.products;

      // If no results, show helpful message
      if (_searchResults.isEmpty) {
        _errorMessage = 'No products found for "$_query". '
            'Make sure your RapidAPI key is configured in Settings → API Key Management.';
      }

      // Record current prices for future comparison
      await _recordCurrentPrices(_searchResults);

      // Cache results only if non-empty
      if (_searchResults.isNotEmpty) {
        _memoryCache[cacheKey] = result.products;
        await _cacheService.setCachedSearch(fileCacheKey, result.products);
      }

      // Record analytics
      await _analyticsService.recordSearch(
        _query,
        result.totalCount,
        stopwatch.elapsedMilliseconds.toDouble(),
        _searchCountry,
      );

      // Get AI recommendation
      _aiRecommendation2 =
          await _aiRecommendation.getRecommendation(_query, result.products);

      // Group results
      await _groupResults();
    } catch (e) {
      _errorMessage = 'Search failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load previous prices from price history for comparison
  Future<void> _loadPreviousPrices(List<Product> products) async {
    _previousPrices.clear();
    for (final p in products) {
      final identifier = FavoriteItem.buildIdentifier(p.name, p.source);
      try {
        final history =
            await _priceHistoryService.getPriceHistory(identifier);
        if (history.isNotEmpty) {
          _previousPrices['${p.name}|${p.source}'] = history.first.price;
        }
      } catch (_) {}
    }
  }

  /// Record current prices so next search can show changes
  Future<void> _recordCurrentPrices(List<Product> products) async {
    for (final p in products) {
      if (p.price > 0) {
        final identifier = FavoriteItem.buildIdentifier(p.name, p.source);
        try {
          await _priceHistoryService.recordPrice(
            identifier,
            p.name,
            p.price,
            p.source,
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _groupResults() async {
    if (_searchResults.isEmpty) {
      _groupedResults = [];
      return;
    }

    final grouped =
        await _groupingService.groupProducts(_searchResults, _query);
    _groupedResults = grouped.productGroups;
  }

  void clearResults() {
    _searchResults = [];
    _groupedResults = [];
    _aiRecommendation2 = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearFilters() {
    _sortOrder = SearchSortOrder.relevance;
    _sourceFilter = EcommerceSource.all;
    _savePreferences();
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches = [];
    _savePreferences();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
