import '../data/product_database.dart';
import '../models/models.dart';

/// Favorites CRUD backed by SQLite Favorites table
class FavoritesService {
  final ProductDatabase _db;

  FavoritesService(this._db);

  Future<List<FavoriteItem>> getFavorites() => _db.getAllFavorites();

  Future<bool> isFavorite(String productName, String? source) async {
    final identifier = FavoriteItem.buildIdentifier(productName, source);
    final item = await _db.getFavoriteByIdentifier(identifier);
    return item != null;
  }

  Future<FavoriteItem?> addFavorite(Product product) async {
    final identifier =
        FavoriteItem.buildIdentifier(product.name, product.source);
    final existing = await _db.getFavoriteByIdentifier(identifier);
    if (existing != null) return existing;

    final item = FavoriteItem(
      productIdentifier: identifier,
      productName: product.name,
      brand: product.brand,
      category: product.category,
      source: product.source,
      price: product.price,
      priceAtSave: product.price,
      averageRating: product.averageRating,
      numberOfRatings: product.numberOfRatings,
      productUrl: product.productUrl,
      imageUrl: product.imageUrl,
      description: product.description,
    );

    final id = await _db.saveFavorite(item);
    item.id = id;
    return item;
  }

  Future<bool> removeFavorite(String productName, String? source) async {
    final identifier = FavoriteItem.buildIdentifier(productName, source);
    final count = await _db.deleteFavoriteByIdentifier(identifier);
    return count > 0;
  }

  Future<bool> toggleFavorite(Product product) async {
    final isFav = await isFavorite(product.name, product.source);
    if (isFav) {
      await removeFavorite(product.name, product.source);
      return false;
    } else {
      await addFavorite(product);
      return true;
    }
  }

  Future<int> getFavoriteCount() => _db.getFavoriteCount();
}
