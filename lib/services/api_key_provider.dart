import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/models.dart';

/// Resolves API keys from Firebase Remote Config → SecureStorage → defaults
class ApiKeyProvider {
  final FlutterSecureStorage _secureStorage;

  ApiKeyProvider({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Key name mapping: SecureStorage key → ApiConfiguration property
  static const _keyMap = {
    'TB_AMAZON_API_KEY': 'amazonApiKey',
    'TB_AMAZON_ASSOC_TAG': 'amazonAssociateTag',
    'TB_WALMART_API_KEY': 'walmartApiKey',
    'TB_WALMART_AFFIL_ID': 'walmartAffiliateId',
    'TB_BESTBUY_API_KEY': 'bestBuyApiKey',
    'TB_BESTBUY_AFFIL_ID': 'bestBuyAffiliateId',
    'TB_TARGET_API_KEY': 'targetApiKey',
    'TB_TARGET_AFFIL_ID': 'targetAffiliateId',
    'TB_EBAY_API_KEY': 'ebayApiKey',
    'TB_FLIPKART_API_KEY': 'flipkartApiKey',
    'TB_FLIPKART_AFFIL_ID': 'flipkartAffiliateId',
    'TB_MYNTRA_API_KEY': 'myntraApiKey',
    'TB_MYNTRA_AFFIL_ID': 'myntraAffiliateId',
    'TB_NYKAA_API_KEY': 'nykaaApiKey',
    'TB_NYKAA_AFFIL_ID': 'nykaaAffiliateId',
    'TB_MEESHO_API_KEY': 'meeshoApiKey',
    'TB_CROMA_API_KEY': 'cromaApiKey',
    'TB_BIGBASKET_API_KEY': 'bigBasketApiKey',
    'TB_JIOMART_API_KEY': 'jioMartApiKey',
    'TB_SWIGGY_API_KEY': 'swiggyApiKey',
    'TB_BLINKIT_API_KEY': 'blinkitApiKey',
    'TB_ZEPTO_API_KEY': 'zeptoApiKey',
  };

  /// Populates ApiConfiguration:
  /// 1. Firebase Remote Config → 2. SecureStorage → 3. default (empty)
  Future<ApiConfiguration> populate(ApiConfiguration config) async {
    // Try Firebase Remote Config first
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.fetchAndActivate();

      for (final entry in _keyMap.entries) {
        final remoteValue = remoteConfig.getString(entry.key);
        if (remoteValue.isNotEmpty) {
          _setConfigValue(config, entry.value, remoteValue);
          continue;
        }
        // Fallback to SecureStorage
        final secureValue = await _secureStorage.read(key: entry.key);
        if (secureValue != null && secureValue.isNotEmpty) {
          _setConfigValue(config, entry.value, secureValue);
        }
      }

      // Feature flags from Remote Config
      final useReal = remoteConfig.getString('TB_USE_REAL_APIS');
      if (useReal.isNotEmpty) {
        config.useRealApis = useReal.toLowerCase() == 'true';
      }
      final enableAffil = remoteConfig.getString('TB_ENABLE_AFFILIATE_LINKS');
      if (enableAffil.isNotEmpty) {
        config.enableAffiliateLinks = enableAffil.toLowerCase() == 'true';
      }
    } catch (_) {
      // Firebase not available — fall back to SecureStorage only
      for (final entry in _keyMap.entries) {
        try {
          final value = await _secureStorage.read(key: entry.key);
          if (value != null && value.isNotEmpty) {
            _setConfigValue(config, entry.value, value);
          }
        } catch (_) {}
      }
    }

    return config;
  }

  /// Save a key to SecureStorage
  Future<void> saveKey(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Read a key from SecureStorage
  Future<String?> readKey(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete a key from SecureStorage  
  Future<void> deleteKey(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Clear all keys
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }

  void _setConfigValue(ApiConfiguration config, String property, String value) {
    switch (property) {
      case 'amazonApiKey':
        config.amazonApiKey = value;
      case 'amazonAssociateTag':
        config.amazonAssociateTag = value;
      case 'walmartApiKey':
        config.walmartApiKey = value;
      case 'walmartAffiliateId':
        config.walmartAffiliateId = value;
      case 'bestBuyApiKey':
        config.bestBuyApiKey = value;
      case 'bestBuyAffiliateId':
        config.bestBuyAffiliateId = value;
      case 'targetApiKey':
        config.targetApiKey = value;
      case 'targetAffiliateId':
        config.targetAffiliateId = value;
      case 'ebayApiKey':
        config.ebayApiKey = value;
      case 'flipkartApiKey':
        config.flipkartApiKey = value;
      case 'flipkartAffiliateId':
        config.flipkartAffiliateId = value;
      case 'myntraApiKey':
        config.myntraApiKey = value;
      case 'myntraAffiliateId':
        config.myntraAffiliateId = value;
      case 'nykaaApiKey':
        config.nykaaApiKey = value;
      case 'nykaaAffiliateId':
        config.nykaaAffiliateId = value;
      case 'meeshoApiKey':
        config.meeshoApiKey = value;
      case 'cromaApiKey':
        config.cromaApiKey = value;
      case 'bigBasketApiKey':
        config.bigBasketApiKey = value;
      case 'jioMartApiKey':
        config.jioMartApiKey = value;
      case 'swiggyApiKey':
        config.swiggyApiKey = value;
      case 'blinkitApiKey':
        config.blinkitApiKey = value;
      case 'zeptoApiKey':
        config.zeptoApiKey = value;
    }
  }
}
