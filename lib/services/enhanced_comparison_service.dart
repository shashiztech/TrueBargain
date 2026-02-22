import '../models/models.dart';
import 'configuration_service.dart';
import 'ai_recommendation_service.dart';

/// AI-assisted verdict + scoring for comparison
class EnhancedComparisonService {
  final AIRecommendationService _aiRecommendation;
  final ConfigurationService _configService;

  EnhancedComparisonService(this._aiRecommendation, this._configService);

  Future<ComparisonVerdict> generateComparisonVerdict(
      List<Product> products, String query) async {
    if (products.isEmpty) {
      return ComparisonVerdict(overallRecommendation: 'No products to compare');
    }

    final bestPrice =
        products.reduce((a, b) => a.price < b.price ? a : b);
    final bestRating = products
        .reduce((a, b) => a.averageRating > b.averageRating ? a : b);

    // Best value: (rating * reviews) / price
    Product? bestValue;
    double bestScore = 0;
    for (final p in products) {
      if (p.price > 0) {
        final score = (p.averageRating * p.numberOfRatings) / p.price;
        if (score > bestScore) {
          bestScore = score;
          bestValue = p;
        }
      }
    }

    final winner = bestValue ?? bestRating;

    // Generate pros/cons
    final prosAndCons = <String, List<String>>{};
    for (final p in products) {
      final pros = <String>[];
      final cons = <String>[];

      if (p.price == bestPrice.price) pros.add('Lowest price');
      if (p.averageRating == bestRating.averageRating) pros.add('Highest rated');
      if (p.numberOfRatings > 1000) pros.add('Well-reviewed');
      if (p.price > bestPrice.price * 1.5) cons.add('Premium priced');
      if (p.averageRating < 3.5) cons.add('Below average rating');
      if (p.numberOfRatings < 100) cons.add('Few reviews');

      prosAndCons[p.name] = [...pros, ...cons.map((c) => '⚠ $c')];
    }

    final confidence = products.length >= 3 ? 0.85 : 0.65;

    return ComparisonVerdict(
      winnerProduct: winner,
      winnerReason: winner == bestValue
          ? 'Best value for money'
          : 'Highest customer satisfaction',
      bestPrice: bestPrice,
      bestRating: bestRating,
      prosAndCons: prosAndCons,
      overallRecommendation:
          'Based on analysis of ${products.length} products for "$query", '
          '${winner.name} offers the best overall deal at '
          '₹${winner.price.toStringAsFixed(0)} with '
          '${winner.averageRating.toStringAsFixed(1)}★ rating.',
      confidenceScore: confidence,
    );
  }

  Future<List<Product>> getBestDeals(
      List<Product> products, ComparisonCriteria criteria) async {
    final sorted = List<Product>.from(products);
    switch (criteria) {
      case ComparisonCriteria.lowestPrice:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case ComparisonCriteria.highestRating:
        sorted.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      case ComparisonCriteria.bestValue:
        sorted.sort((a, b) {
          final av = a.price > 0
              ? (a.averageRating * a.numberOfRatings) / a.price
              : 0.0;
          final bv = b.price > 0
              ? (b.averageRating * b.numberOfRatings) / b.price
              : 0.0;
          return bv.compareTo(av);
        });
      default:
        sorted.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    }
    return sorted.take(5).toList();
  }

  Future<List<String>> getComparisonCriteria() async {
    return ComparisonCriteria.values.map((c) => c.name).toList();
  }
}
