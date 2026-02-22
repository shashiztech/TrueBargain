import 'dart:math';
import '../models/models.dart';

/// In-memory comparison scoring
class ProductComparisonService {
  Future<ProductComparison> compareProducts(
      List<Product> products, ComparisonCriteria criteria) async {
    if (products.isEmpty) {
      return ProductComparison(products: products);
    }

    // Compute scores
    for (final p in products) {
      p.comparisonScore = _computeScore(p, criteria);
    }

    final sorted = List<Product>.from(products)
      ..sort((a, b) => b.comparisonScore.compareTo(a.comparisonScore));

    return ProductComparison(
      products: sorted,
      bestMatch: sorted.first,
      comparisonCriteria: criteria.name,
    );
  }

  Future<Product?> findBestMatch(
      List<Product> products, ComparisonCriteria criteria) async {
    if (products.isEmpty) return null;
    final comparison = await compareProducts(products, criteria);
    return comparison.bestMatch;
  }

  double _computeScore(Product p, ComparisonCriteria criteria) {
    switch (criteria) {
      case ComparisonCriteria.lowestPrice:
        return p.price > 0 ? 1.0 / p.price * 10000 : 0;
      case ComparisonCriteria.highestRating:
        return p.averageRating;
      case ComparisonCriteria.mostReviews:
        return p.numberOfRatings.toDouble();
      case ComparisonCriteria.bestValue:
        if (p.price <= 0) return 0;
        return (p.averageRating * p.numberOfRatings) / p.price;
      case ComparisonCriteria.bestFeatures:
        return p.averageRating * 0.6 + (p.numberOfRatings / 1000) * 0.4;
      case ComparisonCriteria.brandReputation:
        return p.averageRating * 0.5 +
            (min(p.numberOfRatings, 10000) / 10000) * 0.5;
    }
  }
}
