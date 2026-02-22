/// API configuration — populated from Firebase Remote Config / SecureStorage / env vars
class ApiConfiguration {
  // Global
  String amazonApiKey;
  String amazonAssociateTag;
  String walmartApiKey;
  String walmartAffiliateId;
  String bestBuyApiKey;
  String bestBuyAffiliateId;
  String targetApiKey;
  String targetAffiliateId;
  String ebayApiKey;

  // Indian market
  String flipkartApiKey;
  String flipkartAffiliateId;
  String myntraApiKey;
  String myntraAffiliateId;
  String nykaaApiKey;
  String nykaaAffiliateId;
  String meeshoApiKey;
  String cromaApiKey;
  String bigBasketApiKey;
  String jioMartApiKey;
  String swiggyApiKey;
  String blinkitApiKey;
  String zeptoApiKey;

  // Flags
  bool useRealApis;
  bool enableAffiliateLinks;
  int maxRetryAttempts;
  int retryDelayMilliseconds;

  ApiConfiguration({
    this.amazonApiKey = '',
    this.amazonAssociateTag = '',
    this.walmartApiKey = '',
    this.walmartAffiliateId = '',
    this.bestBuyApiKey = '',
    this.bestBuyAffiliateId = '',
    this.targetApiKey = '',
    this.targetAffiliateId = '',
    this.ebayApiKey = '',
    this.flipkartApiKey = '',
    this.flipkartAffiliateId = '',
    this.myntraApiKey = '',
    this.myntraAffiliateId = '',
    this.nykaaApiKey = '',
    this.nykaaAffiliateId = '',
    this.meeshoApiKey = '',
    this.cromaApiKey = '',
    this.bigBasketApiKey = '',
    this.jioMartApiKey = '',
    this.swiggyApiKey = '',
    this.blinkitApiKey = '',
    this.zeptoApiKey = '',
    this.useRealApis = false,
    this.enableAffiliateLinks = false,
    this.maxRetryAttempts = 3,
    this.retryDelayMilliseconds = 1000,
  });
}

/// Persistent favorite with price snapshot — SQLite table "Favorites"
class FavoriteItem {
  int? id;
  String productIdentifier;
  String productName;
  String? brand;
  String? category;
  String? source;
  double price;
  double priceAtSave;
  double averageRating;
  int numberOfRatings;
  String? productUrl;
  String? imageUrl;
  String? description;
  DateTime savedAt;

  FavoriteItem({
    this.id,
    required this.productIdentifier,
    required this.productName,
    this.brand,
    this.category,
    this.source,
    this.price = 0.0,
    this.priceAtSave = 0.0,
    this.averageRating = 0.0,
    this.numberOfRatings = 0,
    this.productUrl,
    this.imageUrl,
    this.description,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  static String buildIdentifier(String name, String? source) =>
      '$name|${source ?? ''}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'productIdentifier': productIdentifier,
        'productName': productName,
        'brand': brand,
        'category': category,
        'source': source,
        'price': price,
        'priceAtSave': priceAtSave,
        'averageRating': averageRating,
        'numberOfRatings': numberOfRatings,
        'productUrl': productUrl,
        'imageUrl': imageUrl,
        'description': description,
        'savedAt': savedAt.toIso8601String(),
      };

  factory FavoriteItem.fromMap(Map<String, dynamic> map) => FavoriteItem(
        id: map['id'] as int?,
        productIdentifier: map['productIdentifier'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
        brand: map['brand'] as String?,
        category: map['category'] as String?,
        source: map['source'] as String?,
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        priceAtSave: (map['priceAtSave'] as num?)?.toDouble() ?? 0.0,
        averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
        numberOfRatings: map['numberOfRatings'] as int? ?? 0,
        productUrl: map['productUrl'] as String?,
        imageUrl: map['imageUrl'] as String?,
        description: map['description'] as String?,
        savedAt: map['savedAt'] != null
            ? DateTime.tryParse(map['savedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Price history entry — SQLite table "PriceHistory"
class PriceHistoryEntry {
  int? id;
  String productIdentifier;
  String productName;
  double price;
  String? currency;
  String? source;
  DateTime recordedAt;

  PriceHistoryEntry({
    this.id,
    required this.productIdentifier,
    required this.productName,
    this.price = 0.0,
    this.currency = 'INR',
    this.source,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'productIdentifier': productIdentifier,
        'productName': productName,
        'price': price,
        'currency': currency,
        'source': source,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory PriceHistoryEntry.fromMap(Map<String, dynamic> map) =>
      PriceHistoryEntry(
        id: map['id'] as int?,
        productIdentifier: map['productIdentifier'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency'] as String?,
        source: map['source'] as String?,
        recordedAt: map['recordedAt'] != null
            ? DateTime.tryParse(map['recordedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Product alert entry — SQLite table "ProductAlerts"
class ProductAlertEntry {
  int? id;
  String productIdentifier;
  String productName;
  String? category;
  double targetPrice;
  double lastKnownPrice;
  bool isActive;
  bool isCategory;
  DateTime createdAt;
  DateTime? lastCheckedAt;
  DateTime? lastNotifiedAt;

  ProductAlertEntry({
    this.id,
    required this.productIdentifier,
    required this.productName,
    this.category,
    this.targetPrice = 0.0,
    this.lastKnownPrice = 0.0,
    this.isActive = true,
    this.isCategory = false,
    DateTime? createdAt,
    this.lastCheckedAt,
    this.lastNotifiedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'productIdentifier': productIdentifier,
        'productName': productName,
        'category': category,
        'targetPrice': targetPrice,
        'lastKnownPrice': lastKnownPrice,
        'isActive': isActive ? 1 : 0,
        'isCategory': isCategory ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'lastCheckedAt': lastCheckedAt?.toIso8601String(),
        'lastNotifiedAt': lastNotifiedAt?.toIso8601String(),
      };

  factory ProductAlertEntry.fromMap(Map<String, dynamic> map) =>
      ProductAlertEntry(
        id: map['id'] as int?,
        productIdentifier: map['productIdentifier'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
        category: map['category'] as String?,
        targetPrice: (map['targetPrice'] as num?)?.toDouble() ?? 0.0,
        lastKnownPrice: (map['lastKnownPrice'] as num?)?.toDouble() ?? 0.0,
        isActive: (map['isActive'] as int?) == 1,
        isCategory: (map['isCategory'] as int?) == 1,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        lastCheckedAt: map['lastCheckedAt'] != null
            ? DateTime.tryParse(map['lastCheckedAt'] as String)
            : null,
        lastNotifiedAt: map['lastNotifiedAt'] != null
            ? DateTime.tryParse(map['lastNotifiedAt'] as String)
            : null,
      );
}

/// Search analytics entry — SQLite table "SearchAnalytics"
class SearchAnalyticsEntry {
  int? id;
  String query;
  int resultCount;
  double responseMs;
  String? region;
  String? sortOrder;
  DateTime searchedAt;

  SearchAnalyticsEntry({
    this.id,
    required this.query,
    this.resultCount = 0,
    this.responseMs = 0.0,
    this.region,
    this.sortOrder,
    DateTime? searchedAt,
  }) : searchedAt = searchedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'query': query,
        'resultCount': resultCount,
        'responseMs': responseMs,
        'region': region,
        'sortOrder': sortOrder,
        'searchedAt': searchedAt.toIso8601String(),
      };

  factory SearchAnalyticsEntry.fromMap(Map<String, dynamic> map) =>
      SearchAnalyticsEntry(
        id: map['id'] as int?,
        query: map['query'] as String? ?? '',
        resultCount: map['resultCount'] as int? ?? 0,
        responseMs: (map['responseMs'] as num?)?.toDouble() ?? 0.0,
        region: map['region'] as String?,
        sortOrder: map['sortOrder'] as String?,
        searchedAt: map['searchedAt'] != null
            ? DateTime.tryParse(map['searchedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
