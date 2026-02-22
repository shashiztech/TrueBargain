import 'product.dart';

/// Sort order for search results
enum SearchSortOrder {
  relevance,
  priceLowToHigh,
  priceHighToLow,
  ratingHighToLow,
  mostReviews,
  newest,
}

/// E-commerce source platforms
enum EcommerceSource {
  all,
  amazon,
  flipkart,
  walmart,
  bestBuy,
  target,
  myntra,
  nykaa,
  meesho,
  croma,
  blinkit,
  swiggy,
  bigBasket,
  jioMart,
  zepto,
  ebay,
  local,
}

/// Search request DTO
class SearchRequest {
  final String query;
  final SearchSortOrder sortOrder;
  final EcommerceSource source;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? category;
  final String? brand;
  final int maxResults;

  SearchRequest({
    required this.query,
    this.sortOrder = SearchSortOrder.relevance,
    this.source = EcommerceSource.all,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.category,
    this.brand,
    this.maxResults = 50,
  });

  SearchRequest copyWith({
    String? query,
    SearchSortOrder? sortOrder,
    EcommerceSource? source,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? category,
    String? brand,
    int? maxResults,
  }) =>
      SearchRequest(
        query: query ?? this.query,
        sortOrder: sortOrder ?? this.sortOrder,
        source: source ?? this.source,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        minRating: minRating ?? this.minRating,
        category: category ?? this.category,
        brand: brand ?? this.brand,
        maxResults: maxResults ?? this.maxResults,
      );
}

/// Search result output
class SearchResult {
  final List<Product> products;
  final int totalCount;
  final String query;
  final Duration searchDuration;
  final Map<EcommerceSource, int> sourceCounts;

  SearchResult({
    required this.products,
    required this.totalCount,
    required this.query,
    required this.searchDuration,
    this.sourceCounts = const {},
  });
}
