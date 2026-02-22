import '../data/product_database.dart';
import '../models/models.dart';
import 'ecommerce_search_service.dart';

/// Price history service — SQLite-backed
class PriceHistoryService {
  final ProductDatabase _db;

  PriceHistoryService(this._db);

  Future<List<PriceHistoryEntry>> getPriceHistory(
      String identifier) async {
    return _db.getPriceHistoryByIdentifier(identifier);
  }

  Future<void> recordPrice(
    String identifier,
    String name,
    double price,
    String? source, {
    String currency = 'INR',
  }) async {
    final entry = PriceHistoryEntry(
      productIdentifier: identifier,
      productName: name,
      price: price,
      currency: currency,
      source: source,
    );
    await _db.savePriceHistory(entry);

    // Auto-purge entries older than 90 days
    await _db.purgePriceHistoryOlderThan(const Duration(days: 90));
  }

  Future<double> getLowestPrice(String identifier, Duration period) async {
    final history = await _db.getPriceHistoryByIdentifier(identifier);
    final cutoff = DateTime.now().subtract(period);
    final recent =
        history.where((h) => h.recordedAt.isAfter(cutoff)).toList();

    if (recent.isEmpty) return 0;
    return recent.map((h) => h.price).reduce((a, b) => a < b ? a : b);
  }

  Future<bool> hasPriceDropped(
      String identifier, double threshold) async {
    final history = await _db.getPriceHistoryByIdentifier(identifier);
    if (history.length < 2) return false;

    final latest = history.first.price;
    final previous = history[1].price;

    return previous > 0 && (previous - latest) / previous >= threshold;
  }
}

/// Product alert service — SQLite-backed
class ProductAlertService {
  final ProductDatabase _db;

  ProductAlertService(this._db);

  Future<List<ProductAlertEntry>> getActiveAlerts() =>
      _db.getActiveAlerts();

  Future<List<ProductAlertEntry>> getAllAlerts() => _db.getAllAlerts();

  Future<int> createAlert(ProductAlertEntry entry) =>
      _db.saveAlert(entry);

  Future<void> deleteAlert(int alertId) => _db.deleteAlert(alertId);

  Future<int> checkAndSendAlerts(
    EcommerceSearchService searchService,
  ) async {
    final activeAlerts = await _db.getActiveAlerts();
    int triggered = 0;

    for (final alert in activeAlerts) {
      try {
        final result = await searchService.searchAllPlatforms(
          SearchRequest(query: alert.productName, maxResults: 5),
        );

        if (result.products.isEmpty) continue;

        final lowestPrice =
            result.products.map((p) => p.price).reduce((a, b) => a < b ? a : b);

        if (lowestPrice <= alert.targetPrice) {
          alert.lastNotifiedAt = DateTime.now();
          triggered++;
        }

        alert.lastKnownPrice = lowestPrice;
        alert.lastCheckedAt = DateTime.now();
        await _db.saveAlert(alert);
      } catch (_) {}
    }

    return triggered;
  }
}
