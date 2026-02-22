import 'dart:math';
import '../models/models.dart';

/// Groups product variants by model/brand/category
class ProductGroupingService {
  /// Brand variation dictionaries for fuzzy matching
  static const _brandVariations = {
    'samsung': ['samsung', 'galaxy'],
    'apple': ['apple', 'iphone', 'ipad', 'macbook'],
    'sony': ['sony', 'playstation', 'ps5'],
    'xiaomi': ['xiaomi', 'mi', 'redmi', 'poco'],
    'oneplus': ['oneplus', 'one plus'],
    'google': ['google', 'pixel'],
    'lg': ['lg', 'life good'],
  };

  Future<GroupedSearchResult> groupProducts(
    List<Product> products,
    String query, {
    ProductGroupingType type = ProductGroupingType.modelMatch,
  }) async {
    final groups = <ProductGroupViewModel>[];

    switch (type) {
      case ProductGroupingType.exactMatch:
        groups.addAll(await _groupByExactName(products));
      case ProductGroupingType.modelMatch:
        groups.addAll(await groupProductsByModel(products));
      case ProductGroupingType.categoryMatch:
        groups.addAll(await groupProductsByCategory(products));
      case ProductGroupingType.brandMatch:
        groups.addAll(await groupProductsByBrand(products));
    }

    // Compute source/brand/category counts
    final sourceCounts = <EcommerceSource, int>{};
    final brandCounts = <String, int>{};
    final categoryCounts = <String, int>{};

    for (final p in products) {
      if (p.brand != null) {
        brandCounts[p.brand!] = (brandCounts[p.brand!] ?? 0) + 1;
      }
      if (p.category != null) {
        categoryCounts[p.category!] =
            (categoryCounts[p.category!] ?? 0) + 1;
      }
    }

    return GroupedSearchResult(
      searchQuery: query,
      productGroups: groups,
      sourceCounts: sourceCounts,
      brandCounts: brandCounts,
      categoryCounts: categoryCounts,
    );
  }

  Future<List<ProductGroupViewModel>> groupProductsByModel(
      List<Product> products) async {
    final groups = <String, List<Product>>{};

    for (final p in products) {
      final model = extractModelName(p.name, p.brand);
      groups.putIfAbsent(model, () => []).add(p);
    }

    return groups.entries.map((e) => _buildGroup(e.key, e.value)).toList();
  }

  Future<List<ProductGroupViewModel>> groupProductsByCategory(
      List<Product> products) async {
    final groups = <String, List<Product>>{};

    for (final p in products) {
      final cat = p.category ?? 'Other';
      groups.putIfAbsent(cat, () => []).add(p);
    }

    return groups.entries.map((e) => _buildGroup(e.key, e.value)).toList();
  }

  Future<List<ProductGroupViewModel>> groupProductsByBrand(
      List<Product> products) async {
    final groups = <String, List<Product>>{};

    for (final p in products) {
      final brand = p.brand ?? 'Unknown';
      groups.putIfAbsent(brand, () => []).add(p);
    }

    return groups.entries.map((e) => _buildGroup(e.key, e.value)).toList();
  }

  Future<List<ProductGroupViewModel>> _groupByExactName(
      List<Product> products) async {
    final groups = <String, List<Product>>{};

    for (final p in products) {
      groups.putIfAbsent(p.name, () => []).add(p);
    }

    return groups.entries.map((e) => _buildGroup(e.key, e.value)).toList();
  }

  String normalizeProductName(String name, String? brand) {
    var normalized = name.toLowerCase().trim();
    if (brand != null) {
      normalized = normalized.replaceAll(brand.toLowerCase(), '').trim();
    }
    return normalized
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), '');
  }

  String extractModelName(String name, String? brand) {
    var model = name;

    // Remove brand name to get model
    if (brand != null) {
      model = model.replaceAll(RegExp(brand, caseSensitive: false), '').trim();
    }

    // Remove common suffixes
    for (final suffix in [
      'edition',
      'version',
      'bundle',
      'pack',
      'set',
      'kit'
    ]) {
      model =
          model.replaceAll(RegExp('\\b$suffix\\b', caseSensitive: false), '');
    }

    return model.trim().isEmpty ? name : '${brand ?? ''} $model'.trim();
  }

  double calculateProductSimilarity(Product p1, Product p2) {
    double score = 0.0;

    // Name similarity (0.4 weight)
    final n1 = normalizeProductName(p1.name, p1.brand);
    final n2 = normalizeProductName(p2.name, p2.brand);
    score += _stringSimilarity(n1, n2) * 0.4;

    // Brand match (0.2 weight)
    if (p1.brand != null &&
        p2.brand != null &&
        p1.brand!.toLowerCase() == p2.brand!.toLowerCase()) {
      score += 0.2;
    }

    // Category match (0.15 weight)
    if (p1.category != null &&
        p2.category != null &&
        p1.category!.toLowerCase() == p2.category!.toLowerCase()) {
      score += 0.15;
    }

    // Price proximity (0.15 weight)
    if (p1.price > 0 && p2.price > 0) {
      final priceRatio = min(p1.price, p2.price) / max(p1.price, p2.price);
      score += priceRatio * 0.15;
    }

    // Rating proximity (0.1 weight)
    final ratingDiff = (p1.averageRating - p2.averageRating).abs();
    score += max(0, 1.0 - ratingDiff / 5.0) * 0.1;

    return score;
  }

  double _stringSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final aWords = a.split(' ').toSet();
    final bWords = b.split(' ').toSet();
    final intersection = aWords.intersection(bWords).length;
    final union = aWords.union(bWords).length;

    return union > 0 ? intersection / union : 0.0;
  }

  ProductGroupViewModel _buildGroup(String name, List<Product> products) {
    final prices = products.map((p) => p.price).where((p) => p > 0);
    final sources = products.map((p) => p.source ?? '').toSet().toList();
    final ratings = products.map((p) => p.averageRating);

    return ProductGroupViewModel(
      groupName: name,
      brand: products.first.brand,
      modelName: name,
      productVariants: products
          .map((p) => ProductVariant(
                product: p,
                source: p.source,
                price: p.price,
              ))
          .toList(),
      minPrice: prices.isEmpty ? 0 : prices.reduce(min),
      maxPrice: prices.isEmpty ? 0 : prices.reduce(max),
      sources: sources,
      averageRating: ratings.isEmpty
          ? 0
          : ratings.reduce((a, b) => a + b) / ratings.length,
    );
  }
}
