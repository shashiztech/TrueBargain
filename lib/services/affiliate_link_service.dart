import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

/// Builds affiliate-tagged URLs for all e-commerce platforms.
///
/// When RapidAPI is used, product URLs are raw (no affiliate tag).
/// This service appends the correct affiliate/associate ID per platform.
/// Falls back to normal URL if no affiliate ID is configured.
class AffiliateLinkService {
  final ApiConfiguration _apiConfig;

  AffiliateLinkService(this._apiConfig);

  /// Build affiliate URL for a product based on its source platform.
  /// If no affiliate ID is configured for that platform, returns the raw URL.
  String getAffiliateUrl(Product product) {
    final rawUrl = product.productUrl ?? '';
    if (rawUrl.isEmpty) return rawUrl;
    if (!_apiConfig.enableAffiliateLinks) return rawUrl;

    final source = (product.source ?? '').toLowerCase();

    // Amazon — tag= parameter
    if (source.contains('amazon') && _apiConfig.amazonAssociateTag.isNotEmpty) {
      return _appendParam(rawUrl, 'tag', _apiConfig.amazonAssociateTag);
    }

    // Flipkart — affid= parameter
    if (source.contains('flipkart') && _apiConfig.flipkartAffiliateId.isNotEmpty) {
      return _appendParam(rawUrl, 'affid', _apiConfig.flipkartAffiliateId);
    }

    // Myntra — utm_source + affiliate tracking
    if (source.contains('myntra') && _apiConfig.myntraAffiliateId.isNotEmpty) {
      return _appendParam(rawUrl, 'utm_source', _apiConfig.myntraAffiliateId);
    }

    // Nykaa — utm_source
    if (source.contains('nykaa') && _apiConfig.nykaaAffiliateId.isNotEmpty) {
      return _appendParam(rawUrl, 'utm_source', _apiConfig.nykaaAffiliateId);
    }

    // Walmart — wmlspartner= parameter
    if (source.contains('walmart') && _apiConfig.walmartAffiliateId.isNotEmpty) {
      return _appendParam(rawUrl, 'wmlspartner', _apiConfig.walmartAffiliateId);
    }

    // Best Buy — ref= parameter
    if (source.contains('best buy') && _apiConfig.bestBuyAffiliateId.isNotEmpty) {
      return _appendParam(rawUrl, 'ref', _apiConfig.bestBuyAffiliateId);
    }

    // Target — afid= parameter
    if (source.contains('target') && _apiConfig.targetAffiliateId.isNotEmpty) {
      return _appendParam(rawUrl, 'afid', _apiConfig.targetAffiliateId);
    }

    // eBay — campid= parameter (eBay Partner Network)
    if (source.contains('ebay') && _apiConfig.ebayApiKey.isNotEmpty) {
      var url = _appendParam(rawUrl, 'campid', _apiConfig.ebayApiKey);
      url = _appendParam(url, 'toolid', '10001');
      url = _appendParam(url, 'mkevt', '1');
      return url;
    }

    // Google Shopping / other — return raw URL
    return rawUrl;
  }

  /// Open product URL in external browser with affiliate link
  Future<bool> openProductUrl(Product product) async {
    final url = getAffiliateUrl(product);
    if (url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Append a query parameter to a URL
  String _appendParam(String url, String key, String value) {
    if (url.contains('?')) {
      return '$url&$key=$value';
    } else {
      return '$url?$key=$value';
    }
  }

  /// Get the platform logo/icon name for display
  static String getPlatformIcon(String? source) {
    if (source == null) return '🛒';
    final s = source.toLowerCase();
    if (s.contains('amazon')) return '🅰️';
    if (s.contains('flipkart')) return '🛍️';
    if (s.contains('walmart')) return '🏪';
    if (s.contains('ebay')) return '🔨';
    if (s.contains('best buy')) return '🏷️';
    if (s.contains('target')) return '🎯';
    if (s.contains('myntra')) return '👗';
    if (s.contains('nykaa')) return '💄';
    if (s.contains('croma')) return '📱';
    if (s.contains('google')) return '🔍';
    return '🛒';
  }
}
