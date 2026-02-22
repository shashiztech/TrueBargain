import 'product.dart';

/// Result of a comparison operation
class ProductComparison {
  final List<Product> products;
  final Product? bestMatch;
  final String comparisonCriteria;
  final DateTime comparisonDate;

  ProductComparison({
    required this.products,
    this.bestMatch,
    this.comparisonCriteria = 'BestValue',
    DateTime? comparisonDate,
  }) : comparisonDate = comparisonDate ?? DateTime.now();
}

/// Filter DTO for search
class SearchFilter {
  String? name;
  String? type;
  String? brand;
  String? category;
  double? minPrice;
  double? maxPrice;
  double? minRating;
  double? maxRating;
  String? source;

  SearchFilter({
    this.name,
    this.type,
    this.brand,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.maxRating,
    this.source,
  });
}
