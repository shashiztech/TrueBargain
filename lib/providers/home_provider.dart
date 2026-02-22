import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Full multi-source search with grouping & caching
class HomeProvider extends ChangeNotifier {
  final EcommerceSearchService _searchService;
  final ProductGroupingService _groupingService;
  final AIRecommendationService _aiRecommendation;
  final CacheService _cacheService;
  final AnalyticsService _analyticsService;
  final ConnectivityService _connectivityService;

  HomeProvider({
    required EcommerceSearchService searchService,
    required ProductGroupingService groupingService,
    required AIRecommendationService aiRecommendation,
    required CacheService cacheService,
    required AnalyticsService analyticsService,
    required ConnectivityService connectivityService,
  })  : _searchService = searchService,
        _groupingService = groupingService,
        _aiRecommendation = aiRecommendation,
        _cacheService = cacheService,
        _analyticsService = analyticsService,
        _connectivityService = connectivityService;

  // State
  List<Product> _searchResults = [];
  List<ProductGroupViewModel> _groupedResults = [];
  String _query = '';
  bool _isLoading = false;
  bool _isGroupedView = true;
  bool _isNlpMode = false;
  String? _errorMessage;
  String? _aiRecommendation2;
  SearchSortOrder _sortOrder = SearchSortOrder.relevance;
  EcommerceSource _sourceFilter = EcommerceSource.all;

  // Cache
  final Map<String, List<Product>> _memoryCache = {};
  Timer? _debounceTimer;

  // Getters
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

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSortOrder(SearchSortOrder order) {
    _sortOrder = order;
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
    notifyListeners();
  }

  void toggleNlpMode() {
    _isNlpMode = !_isNlpMode;
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

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check memory cache
      final cacheKey = '${_query}_${_sourceFilter.name}_${_sortOrder.name}';
      if (_memoryCache.containsKey(cacheKey)) {
        _searchResults = _memoryCache[cacheKey]!;
        await _groupResults();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check file cache
      final fileCacheKey =
          _cacheService.buildCacheKey(_query, 'IN', _sortOrder.name);
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

      _searchResults = result.products;

      // Cache results
      _memoryCache[cacheKey] = result.products;
      await _cacheService.setCachedSearch(fileCacheKey, result.products);

      // Record analytics
      await _analyticsService.recordSearch(
        _query,
        result.totalCount,
        stopwatch.elapsedMilliseconds.toDouble(),
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
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
