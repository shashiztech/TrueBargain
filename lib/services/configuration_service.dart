import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

/// User prefs & e-commerce config (JSON persistence)
class ConfigurationService {
  EcommerceConfiguration? _cachedConfig;
  UserPreferences? _cachedPrefs;

  Future<String> get _appDir async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<EcommerceConfiguration> getConfiguration(
      [String countryCode = 'IN']) async {
    if (_cachedConfig != null) return _cachedConfig!;

    try {
      final path = '${await _appDir}/ecommerce_config.json';
      final file = File(path);
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        _cachedConfig =
            EcommerceConfiguration.fromJson(json as Map<String, dynamic>);
        return _cachedConfig!;
      }
    } catch (_) {}

    // Default configuration
    _cachedConfig = _getDefaultConfig(countryCode);
    return _cachedConfig!;
  }

  Future<void> saveConfiguration(EcommerceConfiguration config) async {
    final path = '${await _appDir}/ecommerce_config.json';
    await File(path).writeAsString(jsonEncode(config.toJson()));
    _cachedConfig = config;
  }

  Future<List<CountrySettings>> getSupportedCountries() async {
    return [
      CountrySettings(
          countryCode: 'IN',
          countryName: 'India',
          currency: 'INR',
          currencySymbol: '₹',
          timeZone: 'Asia/Kolkata'),
      CountrySettings(
          countryCode: 'US',
          countryName: 'United States',
          currency: 'USD',
          currencySymbol: '\$',
          timeZone: 'America/New_York'),
      CountrySettings(
          countryCode: 'GB',
          countryName: 'United Kingdom',
          currency: 'GBP',
          currencySymbol: '£',
          timeZone: 'Europe/London'),
      CountrySettings(
          countryCode: 'CA',
          countryName: 'Canada',
          currency: 'CAD',
          currencySymbol: 'C\$',
          timeZone: 'America/Toronto'),
      CountrySettings(
          countryCode: 'AU',
          countryName: 'Australia',
          currency: 'AUD',
          currencySymbol: 'A\$',
          timeZone: 'Australia/Sydney'),
      CountrySettings(
          countryCode: 'DE',
          countryName: 'Germany',
          currency: 'EUR',
          currencySymbol: '€',
          timeZone: 'Europe/Berlin'),
      CountrySettings(
          countryCode: 'JP',
          countryName: 'Japan',
          currency: 'JPY',
          currencySymbol: '¥',
          timeZone: 'Asia/Tokyo'),
    ];
  }

  Future<UserPreferences> getUserPreferences() async {
    if (_cachedPrefs != null) return _cachedPrefs!;

    try {
      final path = '${await _appDir}/user_preferences.json';
      final file = File(path);
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        _cachedPrefs =
            UserPreferences.fromJson(json as Map<String, dynamic>);
        return _cachedPrefs!;
      }
    } catch (_) {}

    _cachedPrefs = UserPreferences();
    return _cachedPrefs!;
  }

  Future<void> saveUserPreferences(UserPreferences prefs) async {
    final path = '${await _appDir}/user_preferences.json';
    await File(path).writeAsString(jsonEncode(prefs.toJson()));
    _cachedPrefs = prefs;
  }

  Future<List<EcommerceWebsite>> getWebsitesForCountry(String code) async {
    final config = await getConfiguration(code);
    return config.websites;
  }

  EcommerceConfiguration _getDefaultConfig(String countryCode) {
    final websites = <EcommerceWebsite>[];
    if (countryCode == 'IN') {
      websites.addAll([
        EcommerceWebsite(
            name: 'Amazon India',
            baseUrl: 'https://www.amazon.in',
            searchUrlPattern: 'https://www.amazon.in/s?k={query}'),
        EcommerceWebsite(
            name: 'Flipkart',
            baseUrl: 'https://www.flipkart.com',
            searchUrlPattern:
                'https://www.flipkart.com/search?q={query}'),
        EcommerceWebsite(
            name: 'Myntra',
            baseUrl: 'https://www.myntra.com',
            type: WebsiteType.marketplace),
        EcommerceWebsite(
            name: 'Nykaa',
            baseUrl: 'https://www.nykaa.com',
            type: WebsiteType.marketplace),
        EcommerceWebsite(
            name: 'Croma',
            baseUrl: 'https://www.croma.com',
            type: WebsiteType.electronicsSpecialist),
        EcommerceWebsite(
            name: 'Blinkit',
            baseUrl: 'https://www.blinkit.com',
            type: WebsiteType.groceryDelivery),
        EcommerceWebsite(
            name: 'Swiggy Instamart',
            baseUrl: 'https://www.swiggy.com',
            type: WebsiteType.groceryDelivery),
        EcommerceWebsite(
            name: 'BigBasket',
            baseUrl: 'https://www.bigbasket.com',
            type: WebsiteType.groceryDelivery),
      ]);
    } else {
      websites.addAll([
        EcommerceWebsite(
            name: 'Amazon',
            baseUrl: 'https://www.amazon.com',
            searchUrlPattern: 'https://www.amazon.com/s?k={query}'),
        EcommerceWebsite(
            name: 'Walmart',
            baseUrl: 'https://www.walmart.com'),
        EcommerceWebsite(
            name: 'Best Buy',
            baseUrl: 'https://www.bestbuy.com',
            type: WebsiteType.electronicsSpecialist),
        EcommerceWebsite(
            name: 'eBay',
            baseUrl: 'https://www.ebay.com',
            type: WebsiteType.marketplace),
        EcommerceWebsite(
            name: 'Target',
            baseUrl: 'https://www.target.com'),
      ]);
    }

    return EcommerceConfiguration(
      country: countryCode,
      currency: countryCode == 'IN' ? 'INR' : 'USD',
      currencySymbol: countryCode == 'IN' ? '₹' : '\$',
      websites: websites,
    );
  }
}
