import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Product detail: AI summary, price history, alerts
class ProductDetailProvider extends ChangeNotifier {
  final Product product;
  final AIRecommendationService _aiRecommendation;
  final PriceHistoryService _priceHistory;
  final ProductAlertService _alertService;
  final FavoritesService _favoritesService;

  ProductDetailProvider({
    required this.product,
    required AIRecommendationService aiRecommendation,
    required PriceHistoryService priceHistory,
    required ProductAlertService alertService,
    required FavoritesService favoritesService,
  })  : _aiRecommendation = aiRecommendation,
        _priceHistory = priceHistory,
        _alertService = alertService,
        _favoritesService = favoritesService;

  List<PriceHistoryEntry> _priceHistoryEntries = [];
  List<Product> _similarProducts = [];
  String? _aiSummary;
  bool _isLoadingSummary = false;
  bool _isFavorite = false;
  double _targetPrice = 0;

  List<PriceHistoryEntry> get priceHistoryEntries => _priceHistoryEntries;
  List<Product> get similarProducts => _similarProducts;
  String? get aiSummary => _aiSummary;
  bool get isLoadingSummary => _isLoadingSummary;
  bool get isFavorite => _isFavorite;
  double get targetPrice => _targetPrice;

  Future<void> loadDetails() async {
    _isLoadingSummary = true;
    notifyListeners();

    try {
      // Load in parallel
      final identifier =
          FavoriteItem.buildIdentifier(product.name, product.source);

      final results = await Future.wait([
        _priceHistory.getPriceHistory(identifier),
        _aiRecommendation.getSimilarProducts(product),
        _aiRecommendation.generateProductSummary(product),
        _favoritesService.isFavorite(product.name, product.source),
      ]);

      _priceHistoryEntries = results[0] as List<PriceHistoryEntry>;
      _similarProducts = results[1] as List<Product>;
      _aiSummary = results[2] as String;
      _isFavorite = results[3] as bool;
    } catch (_) {}

    _isLoadingSummary = false;
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    _isFavorite = await _favoritesService.toggleFavorite(product);
    notifyListeners();
  }

  void setTargetPrice(double price) {
    _targetPrice = price;
    notifyListeners();
  }

  Future<void> setPriceAlert() async {
    if (_targetPrice <= 0) return;

    final identifier =
        FavoriteItem.buildIdentifier(product.name, product.source);

    await _alertService.createAlert(ProductAlertEntry(
      productIdentifier: identifier,
      productName: product.name,
      category: product.category,
      targetPrice: _targetPrice,
      lastKnownPrice: product.price,
    ));
  }
}
