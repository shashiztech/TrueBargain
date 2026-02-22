import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// AI-assisted comparison with best-choice ribbon
class CompareProvider extends ChangeNotifier {
  final EcommerceSearchService _searchService;
  final AIRecommendationService _aiRecommendation;
  final ProductComparisonService _comparisonService;
  final ProductGroupingService _groupingService;
  final EnhancedComparisonService _enhancedComparison;

  CompareProvider({
    required EcommerceSearchService searchService,
    required AIRecommendationService aiRecommendation,
    required ProductComparisonService comparisonService,
    required ProductGroupingService groupingService,
    required EnhancedComparisonService enhancedComparison,
  })  : _searchService = searchService,
        _aiRecommendation = aiRecommendation,
        _comparisonService = comparisonService,
        _groupingService = groupingService,
        _enhancedComparison = enhancedComparison;

  List<Product> _products = [];
  Product? _bestOverall;
  Product? _bestPrice;
  Product? _bestRating;
  Product? _bestValue;
  Product? _bestChoice;
  ComparisonVerdict? _verdict;
  bool _isLoading = false;
  bool _isComparing = false;
  String? _errorMessage;

  List<Product> get products => _products;
  Product? get bestOverall => _bestOverall;
  Product? get bestPrice => _bestPrice;
  Product? get bestRating => _bestRating;
  Product? get bestValue => _bestValue;
  Product? get bestChoice => _bestChoice;
  ComparisonVerdict? get verdict => _verdict;
  bool get isLoading => _isLoading;
  bool get isComparing => _isComparing;
  String? get errorMessage => _errorMessage;
  bool get hasProducts => _products.isNotEmpty;

  /// Search and add products to comparison
  Future<void> searchAndAdd(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _searchService.searchAllPlatforms(
        SearchRequest(query: query, maxResults: 20),
      );

      // Group by model, pick best from each group
      final grouped =
          await _groupingService.groupProductsByModel(result.products);

      _products = [];
      for (final group in grouped) {
        if (group.productVariants.isNotEmpty) {
          // Pick best-rated variant from each group
          final variants = group.productVariants.toList()
            ..sort((a, b) =>
                b.product.averageRating.compareTo(a.product.averageRating));
          _products.add(variants.first.product);
        }
      }

      if (_products.isEmpty) {
        _products = result.products.take(10).toList();
      }
    } catch (e) {
      _errorMessage = 'Search failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addProduct(Product product) {
    if (!_products.any((p) => p.name == product.name && p.source == product.source)) {
      _products.add(product);
      notifyListeners();
    }
  }

  void removeProduct(Product product) {
    _products.removeWhere(
        (p) => p.name == product.name && p.source == product.source);
    notifyListeners();
  }

  void clearAll() {
    _products = [];
    _bestOverall = null;
    _bestPrice = null;
    _bestRating = null;
    _bestValue = null;
    _bestChoice = null;
    _verdict = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Generate full comparison with AI verdict
  Future<void> generateComparison() async {
    if (_products.length < 2) {
      _errorMessage = 'Add at least 2 products to compare';
      notifyListeners();
      return;
    }

    _isComparing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get comparison verdict
      _verdict = await _enhancedComparison.generateComparisonVerdict(
          _products, _products.first.name);

      _bestPrice = _verdict?.bestPrice;
      _bestRating = _verdict?.bestRating;
      _bestOverall = _verdict?.winnerProduct;

      // Best value calculation
      final valueComparison = await _comparisonService.compareProducts(
          _products, ComparisonCriteria.bestValue);
      _bestValue = valueComparison.bestMatch;

      // Best choice = AI winner or best value
      _bestChoice = _bestOverall ?? _bestValue;
    } catch (e) {
      _errorMessage = 'Comparison failed: ${e.toString()}';
    } finally {
      _isComparing = false;
      notifyListeners();
    }
  }
}
