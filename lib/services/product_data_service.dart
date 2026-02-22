import '../data/product_database.dart';
import '../models/models.dart';

/// CRUD abstraction over ProductDatabase
class ProductDataService {
  final ProductDatabase _db;

  ProductDataService(this._db);

  Future<List<Product>> getAllProducts() => _db.getAllProducts();

  Future<Product?> getProductById(int id) => _db.getProductById(id);

  Future<List<Product>> searchProducts(SearchFilter filter) =>
      _db.searchProducts(filter);

  Future<int> saveProduct(Product product) => _db.saveProduct(product);

  Future<int> deleteProduct(Product product) => _db.deleteProduct(product);

  /// Projects FavoriteItem → Product for legacy callers
  Future<List<Product>> getFavoriteProducts() async {
    final favorites = await _db.getAllFavorites();
    return favorites
        .map((f) => Product(
              name: f.productName,
              price: f.price,
              source: f.source,
              brand: f.brand,
              category: f.category,
              averageRating: f.averageRating,
              numberOfRatings: f.numberOfRatings,
              imageUrl: f.imageUrl,
              productUrl: f.productUrl,
              description: f.description,
              isFavorite: true,
            ))
        .toList();
  }
}
