import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

/// File-system JSON search cache (SHA-256 keyed)
class CacheService {
  Future<String> get _cacheDir async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory('${dir.path}/search_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  String buildCacheKey(String query, String region, String sortOrder) {
    final input = '$query+$region+$sortOrder';
    final hash = sha256.convert(utf8.encode(input)).toString();
    return hash.substring(0, 24);
  }

  Future<List<Product>?> getCachedSearch(
      String key, Duration maxAge) async {
    try {
      final path = '${await _cacheDir}/$key.json';
      final file = File(path);
      if (!await file.exists()) return null;

      final stat = await file.stat();
      if (DateTime.now().difference(stat.modified) > maxAge) {
        await file.delete();
        return null;
      }

      final jsonStr = await file.readAsString();
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((j) => Product.fromMap(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> setCachedSearch(String key, List<Product> products) async {
    try {
      final path = '${await _cacheDir}/$key.json';
      final jsonStr =
          jsonEncode(products.map((p) => p.toMap()).toList());
      await File(path).writeAsString(jsonStr);
    } catch (_) {}
  }

  Future<void> purgeExpiredCache(Duration maxAge) async {
    try {
      final dir = Directory(await _cacheDir);
      if (!await dir.exists()) return;

      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (DateTime.now().difference(stat.modified) > maxAge) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> clearAllCache() async {
    try {
      final dir = Directory(await _cacheDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
