import 'product.dart';

/// E-commerce configuration
class EcommerceConfiguration {
  String country;
  String currency;
  String currencySymbol;
  List<EcommerceWebsite> websites;
  bool enableWebScraping;
  bool enableLocalStores;
  bool enablePublicApis;
  bool enablePriceAlerts;

  EcommerceConfiguration({
    this.country = 'IN',
    this.currency = 'INR',
    this.currencySymbol = '₹',
    this.websites = const [],
    this.enableWebScraping = false,
    this.enableLocalStores = false,
    this.enablePublicApis = true,
    this.enablePriceAlerts = true,
  });

  Map<String, dynamic> toJson() => {
        'country': country,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'websites': websites.map((w) => w.toJson()).toList(),
        'enableWebScraping': enableWebScraping,
        'enableLocalStores': enableLocalStores,
        'enablePublicApis': enablePublicApis,
        'enablePriceAlerts': enablePriceAlerts,
      };

  factory EcommerceConfiguration.fromJson(Map<String, dynamic> json) =>
      EcommerceConfiguration(
        country: json['country'] as String? ?? 'IN',
        currency: json['currency'] as String? ?? 'INR',
        currencySymbol: json['currencySymbol'] as String? ?? '₹',
        websites: (json['websites'] as List?)
                ?.map((w) =>
                    EcommerceWebsite.fromJson(w as Map<String, dynamic>))
                .toList() ??
            [],
        enableWebScraping: json['enableWebScraping'] as bool? ?? false,
        enableLocalStores: json['enableLocalStores'] as bool? ?? false,
        enablePublicApis: json['enablePublicApis'] as bool? ?? true,
        enablePriceAlerts: json['enablePriceAlerts'] as bool? ?? true,
      );
}

/// E-commerce website configuration
class EcommerceWebsite {
  String name;
  String baseUrl;
  String? searchUrlPattern;
  bool isEnabled;
  WebsiteType type;
  ScrapingConfiguration? scrapingConfig;

  EcommerceWebsite({
    required this.name,
    required this.baseUrl,
    this.searchUrlPattern,
    this.isEnabled = true,
    this.type = WebsiteType.generalEcommerce,
    this.scrapingConfig,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'baseUrl': baseUrl,
        'searchUrlPattern': searchUrlPattern,
        'isEnabled': isEnabled,
        'type': type.name,
        'scrapingConfig': scrapingConfig?.toJson(),
      };

  factory EcommerceWebsite.fromJson(Map<String, dynamic> json) =>
      EcommerceWebsite(
        name: json['name'] as String? ?? '',
        baseUrl: json['baseUrl'] as String? ?? '',
        searchUrlPattern: json['searchUrlPattern'] as String?,
        isEnabled: json['isEnabled'] as bool? ?? true,
        type: WebsiteType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => WebsiteType.generalEcommerce,
        ),
        scrapingConfig: json['scrapingConfig'] != null
            ? ScrapingConfiguration.fromJson(
                json['scrapingConfig'] as Map<String, dynamic>)
            : null,
      );
}

enum WebsiteType {
  generalEcommerce,
  electronicsSpecialist,
  groceryDelivery,
  localRetail,
  priceComparison,
  marketplace,
}

class ScrapingConfiguration {
  String? productSelector;
  String? nameSelector;
  String? priceSelector;
  String? ratingSelector;
  String? imageSelector;
  String? linkSelector;
  Map<String, String> headers;
  int delayBetweenRequests;
  bool requiresJavaScript;

  ScrapingConfiguration({
    this.productSelector,
    this.nameSelector,
    this.priceSelector,
    this.ratingSelector,
    this.imageSelector,
    this.linkSelector,
    this.headers = const {},
    this.delayBetweenRequests = 1000,
    this.requiresJavaScript = false,
  });

  Map<String, dynamic> toJson() => {
        'productSelector': productSelector,
        'nameSelector': nameSelector,
        'priceSelector': priceSelector,
        'ratingSelector': ratingSelector,
        'imageSelector': imageSelector,
        'linkSelector': linkSelector,
        'headers': headers,
        'delayBetweenRequests': delayBetweenRequests,
        'requiresJavaScript': requiresJavaScript,
      };

  factory ScrapingConfiguration.fromJson(Map<String, dynamic> json) =>
      ScrapingConfiguration(
        productSelector: json['productSelector'] as String?,
        nameSelector: json['nameSelector'] as String?,
        priceSelector: json['priceSelector'] as String?,
        ratingSelector: json['ratingSelector'] as String?,
        imageSelector: json['imageSelector'] as String?,
        linkSelector: json['linkSelector'] as String?,
        headers: (json['headers'] as Map?)?.cast<String, String>() ?? {},
        delayBetweenRequests:
            json['delayBetweenRequests'] as int? ?? 1000,
        requiresJavaScript: json['requiresJavaScript'] as bool? ?? false,
      );
}

/// Country settings
class CountrySettings {
  final String countryCode;
  final String countryName;
  final String currency;
  final String currencySymbol;
  final String timeZone;
  final double taxRate;

  CountrySettings({
    required this.countryCode,
    required this.countryName,
    required this.currency,
    required this.currencySymbol,
    this.timeZone = 'Asia/Kolkata',
    this.taxRate = 0.18,
  });

  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'countryName': countryName,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'timeZone': timeZone,
        'taxRate': taxRate,
      };

  factory CountrySettings.fromJson(Map<String, dynamic> json) =>
      CountrySettings(
        countryCode: json['countryCode'] as String? ?? 'IN',
        countryName: json['countryName'] as String? ?? 'India',
        currency: json['currency'] as String? ?? 'INR',
        currencySymbol: json['currencySymbol'] as String? ?? '₹',
        timeZone: json['timeZone'] as String? ?? 'Asia/Kolkata',
        taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.18,
      );
}

/// User preferences
class UserPreferences {
  String userId;
  String? postalCode;
  String? city;
  double? latitude;
  double? longitude;
  CountrySettings? countrySettings;
  List<String> preferredCategories;
  List<String> preferredBrands;
  double maxBudget;
  bool isPremiumUser;

  UserPreferences({
    this.userId = 'default_user',
    this.postalCode,
    this.city,
    this.latitude,
    this.longitude,
    this.countrySettings,
    this.preferredCategories = const [],
    this.preferredBrands = const [],
    this.maxBudget = 50000.0,
    this.isPremiumUser = false,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'postalCode': postalCode,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'countrySettings': countrySettings?.toJson(),
        'preferredCategories': preferredCategories,
        'preferredBrands': preferredBrands,
        'maxBudget': maxBudget,
        'isPremiumUser': isPremiumUser,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        userId: json['userId'] as String? ?? 'default_user',
        postalCode: json['postalCode'] as String?,
        city: json['city'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        countrySettings: json['countrySettings'] != null
            ? CountrySettings.fromJson(
                json['countrySettings'] as Map<String, dynamic>)
            : null,
        preferredCategories:
            (json['preferredCategories'] as List?)?.cast<String>() ?? [],
        preferredBrands:
            (json['preferredBrands'] as List?)?.cast<String>() ?? [],
        maxBudget: (json['maxBudget'] as num?)?.toDouble() ?? 50000.0,
        isPremiumUser: json['isPremiumUser'] as bool? ?? false,
      );
}

/// Price alert model (legacy in-memory)
class PriceAlert {
  final String id;
  final String userId;
  final String query;
  final double targetPrice;
  double? currentPrice;
  bool isTriggered;
  DateTime createdAt;
  DateTime? lastCheckedAt;

  PriceAlert({
    required this.id,
    required this.userId,
    required this.query,
    required this.targetPrice,
    this.currentPrice,
    this.isTriggered = false,
    DateTime? createdAt,
    this.lastCheckedAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// AI comparison verdict
class ComparisonVerdict {
  final Product? winnerProduct;
  final String winnerReason;
  final Product? bestPrice;
  final Product? bestRating;
  final Map<String, List<String>> prosAndCons;
  final String overallRecommendation;
  final double confidenceScore;

  ComparisonVerdict({
    this.winnerProduct,
    this.winnerReason = '',
    this.bestPrice,
    this.bestRating,
    this.prosAndCons = const {},
    this.overallRecommendation = '',
    this.confidenceScore = 0.0,
  });
}
