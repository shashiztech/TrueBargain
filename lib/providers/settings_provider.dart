import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Settings MVVM abstraction
class SettingsProvider extends ChangeNotifier {
  final ConfigurationService _configService;
  final ApiKeyProvider _apiKeyProvider;

  SettingsProvider({
    required ConfigurationService configService,
    required ApiKeyProvider apiKeyProvider,
  })  : _configService = configService,
        _apiKeyProvider = apiKeyProvider;

  EcommerceConfiguration? _config;
  UserPreferences? _preferences;
  List<CountrySettings> _countries = [];
  bool _isLoading = false;
  String? _selectedCountry;

  EcommerceConfiguration? get config => _config;
  UserPreferences? get preferences => _preferences;
  List<CountrySettings> get countries => _countries;
  bool get isLoading => _isLoading;
  String? get selectedCountry => _selectedCountry;

  // Feature toggles
  bool get enableWebScraping => _config?.enableWebScraping ?? false;
  bool get enablePublicApis => _config?.enablePublicApis ?? true;
  bool get enableLocalStores => _config?.enableLocalStores ?? false;
  bool get enablePriceAlerts => _config?.enablePriceAlerts ?? true;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _config = await _configService.getConfiguration();
      _preferences = await _configService.getUserPreferences();
      _countries = await _configService.getSupportedCountries();
      _selectedCountry = _config?.country ?? 'IN';
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> save() async {
    if (_config != null) {
      await _configService.saveConfiguration(_config!);
    }
    if (_preferences != null) {
      await _configService.saveUserPreferences(_preferences!);
    }
  }

  void setCountry(String countryCode) {
    _selectedCountry = countryCode;
    _config?.country = countryCode;

    final country = _countries.firstWhere(
      (c) => c.countryCode == countryCode,
      orElse: () => CountrySettings(
        countryCode: 'IN',
        countryName: 'India',
        currency: 'INR',
        currencySymbol: '₹',
      ),
    );

    _config?.currency = country.currency;
    _config?.currencySymbol = country.currencySymbol;
    notifyListeners();
  }

  void setEnableWebScraping(bool value) {
    _config?.enableWebScraping = value;
    notifyListeners();
  }

  void setEnablePublicApis(bool value) {
    _config?.enablePublicApis = value;
    notifyListeners();
  }

  void setEnableLocalStores(bool value) {
    _config?.enableLocalStores = value;
    notifyListeners();
  }

  void setEnablePriceAlerts(bool value) {
    _config?.enablePriceAlerts = value;
    notifyListeners();
  }

  Future<void> saveApiKey(String key, String value) async {
    await _apiKeyProvider.saveKey(key, value);
  }

  Future<String?> readApiKey(String key) async {
    return await _apiKeyProvider.readKey(key);
  }

  Future<void> resetDefaults() async {
    _config = await _configService.getConfiguration('IN');
    _preferences = UserPreferences();
    notifyListeners();
  }
}
