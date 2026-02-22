import 'product.dart';
import 'search_models.dart';

/// User tier
enum UserTier { free, premium, enterprise }

/// Search engine type
enum SearchEngineType { google, bing, duckDuckGo, priceComparison, direct }

/// Comparison criteria
enum ComparisonCriteria {
  bestValue,
  lowestPrice,
  highestRating,
  mostReviews,
  bestFeatures,
  brandReputation,
}

/// Alert type
enum AlertType { priceAlert, stockAlert, aiComparison }

/// Product grouping type
enum ProductGroupingType { exactMatch, modelMatch, categoryMatch, brandMatch }

/// User profile
class UserProfile {
  final UserTier tier;
  final String? country;
  final String? region;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String currency;
  final String language;
  final bool locationTrackingConsent;

  UserProfile({
    this.tier = UserTier.free,
    this.country,
    this.region,
    this.city,
    this.latitude,
    this.longitude,
    this.currency = 'INR',
    this.language = 'en',
    this.locationTrackingConsent = false,
  });
}

/// Country info
class CountryInfo {
  final String code;
  final String name;
  final String currency;
  final String flag;
  final List<String> languages;
  final List<String> popularEcommerceSites;

  CountryInfo({
    required this.code,
    required this.name,
    required this.currency,
    this.flag = '',
    this.languages = const ['en'],
    this.popularEcommerceSites = const [],
  });
}

/// Location info
class LocationInfo {
  final String? country;
  final String? region;
  final String? city;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final bool isAutoDetected;

  LocationInfo({
    this.country,
    this.region,
    this.city,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.isAutoDetected = false,
  });
}

/// Localized search request
class LocalizedSearchRequest extends SearchRequest {
  final String? countryCode;
  final String? regionCode;
  final String? currencyCode;
  final String? languageCode;
  final bool includeLocalStores;
  final bool usePublicEndpoints;
  final UserTier userTier;

  LocalizedSearchRequest({
    required super.query,
    super.sortOrder,
    super.source,
    super.minPrice,
    super.maxPrice,
    super.minRating,
    super.category,
    super.brand,
    super.maxResults,
    this.countryCode,
    this.regionCode,
    this.currencyCode,
    this.languageCode,
    this.includeLocalStores = false,
    this.usePublicEndpoints = true,
    this.userTier = UserTier.free,
  });
}

/// Enhanced product comparison with AI
class EnhancedProductComparison {
  final List<Product> products;
  final Product? bestOverall;
  final Product? bestPrice;
  final Product? bestRating;
  final Product? bestValue;
  final String? aiVerdict;
  final bool isAIGenerated;

  EnhancedProductComparison({
    this.products = const [],
    this.bestOverall,
    this.bestPrice,
    this.bestRating,
    this.bestValue,
    this.aiVerdict,
    this.isAIGenerated = false,
  });
}

/// Product group for display
class ProductGroupViewModel {
  final String groupName;
  final String? brand;
  final String? modelName;
  final List<ProductVariant> productVariants;
  final double minPrice;
  final double maxPrice;
  final List<String> sources;
  final double averageRating;

  ProductGroupViewModel({
    required this.groupName,
    this.brand,
    this.modelName,
    this.productVariants = const [],
    this.minPrice = 0.0,
    this.maxPrice = 0.0,
    this.sources = const [],
    this.averageRating = 0.0,
  });
}

/// Individual variant within a group
class ProductVariant {
  final Product product;
  final String? source;
  final double price;
  final bool isInStock;
  final double? storeRating;
  final String? priceChangeIndicator;

  ProductVariant({
    required this.product,
    this.source,
    this.price = 0.0,
    this.isInStock = true,
    this.storeRating,
    this.priceChangeIndicator,
  });
}

/// Grouped search result
class GroupedSearchResult {
  final String searchQuery;
  final List<ProductGroupViewModel> productGroups;
  final Map<EcommerceSource, int> sourceCounts;
  final Map<String, int> brandCounts;
  final Map<String, int> categoryCounts;

  GroupedSearchResult({
    required this.searchQuery,
    this.productGroups = const [],
    this.sourceCounts = const {},
    this.brandCounts = const {},
    this.categoryCounts = const {},
  });
}
