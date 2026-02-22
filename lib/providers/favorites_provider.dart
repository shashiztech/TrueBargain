import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Favorites list with price-drop badges
class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService;

  FavoritesProvider({required FavoritesService favoritesService})
      : _favoritesService = favoritesService;

  List<FavoriteItem> _favorites = [];
  bool _isLoading = false;

  List<FavoriteItem> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get hasFavorites => _favorites.isNotEmpty;
  bool get isEmpty => _favorites.isEmpty;
  int get count => _favorites.length;

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _favoritesService.getFavorites();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleFavorite(Product product) async {
    final result = await _favoritesService.toggleFavorite(product);
    await loadFavorites();
    return result;
  }

  Future<void> removeFavorite(FavoriteItem item) async {
    await _favoritesService.removeFavorite(item.productName, item.source);
    await loadFavorites();
  }

  Future<void> clearAllFavorites() async {
    for (final fav in List.from(_favorites)) {
      await _favoritesService.removeFavorite(fav.productName, fav.source);
    }
    await loadFavorites();
  }

  Future<bool> isFavorite(String name, String? source) =>
      _favoritesService.isFavorite(name, source);

  /// Price change label for badge
  static String getPriceChangeLabel(FavoriteItem item) {
    if (item.priceAtSave <= 0 || item.price <= 0) return '';

    final diff = item.priceAtSave - item.price;
    final pct = (diff / item.priceAtSave * 100).abs().toStringAsFixed(0);

    if (diff > 0) {
      return 'Price dropped $pct% since saved!';
    } else if (diff < 0) {
      return 'Price up $pct% since saved';
    }
    return 'Price unchanged';
  }
}
