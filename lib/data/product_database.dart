import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

/// SQLite async wrapper — 5 tables, thread-safe initialization
class ProductDatabase {
  static Database? _database;
  static final _initLock = Completer<void>();
  static bool _isInitializing = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (!_isInitializing) {
      _isInitializing = true;
      _database = await _initDatabase();
      if (!_initLock.isCompleted) _initLock.complete();
    } else {
      await _initLock.future;
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'products.db3');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT,
            sku TEXT,
            price REAL DEFAULT 0,
            numberOfRatings INTEGER DEFAULT 0,
            averageRating REAL DEFAULT 0,
            source TEXT,
            description TEXT,
            imageUrl TEXT,
            brand TEXT,
            category TEXT,
            dateAdded TEXT,
            isFavorite INTEGER DEFAULT 0,
            productUrl TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS Favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productIdentifier TEXT,
            productName TEXT,
            brand TEXT,
            category TEXT,
            source TEXT,
            price REAL DEFAULT 0,
            priceAtSave REAL DEFAULT 0,
            averageRating REAL DEFAULT 0,
            numberOfRatings INTEGER DEFAULT 0,
            productUrl TEXT,
            imageUrl TEXT,
            description TEXT,
            savedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS PriceHistory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productIdentifier TEXT,
            productName TEXT,
            price REAL DEFAULT 0,
            currency TEXT DEFAULT 'INR',
            source TEXT,
            recordedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS ProductAlerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productIdentifier TEXT,
            productName TEXT,
            category TEXT,
            targetPrice REAL DEFAULT 0,
            lastKnownPrice REAL DEFAULT 0,
            isActive INTEGER DEFAULT 1,
            isCategory INTEGER DEFAULT 0,
            createdAt TEXT,
            lastCheckedAt TEXT,
            lastNotifiedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS SearchAnalytics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT,
            resultCount INTEGER DEFAULT 0,
            responseMs REAL DEFAULT 0,
            region TEXT,
            sortOrder TEXT,
            searchedAt TEXT
          )
        ''');
      },
    );
  }

  // ──── Products ────
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('Products');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query('Products', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Product.fromMap(maps.first);
  }

  Future<int> saveProduct(Product product) async {
    final db = await database;
    if (product.id != null) {
      return db.update('Products', product.toMap(),
          where: 'id = ?', whereArgs: [product.id]);
    }
    return db.insert('Products', product.toMap());
  }

  Future<int> deleteProduct(Product product) async {
    final db = await database;
    return db.delete('Products', where: 'id = ?', whereArgs: [product.id]);
  }

  Future<List<Product>> searchProducts(SearchFilter filter) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (filter.name != null && filter.name!.isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%${filter.name}%');
    }
    if (filter.brand != null && filter.brand!.isNotEmpty) {
      where.add('brand LIKE ?');
      args.add('%${filter.brand}%');
    }
    if (filter.category != null && filter.category!.isNotEmpty) {
      where.add('category LIKE ?');
      args.add('%${filter.category}%');
    }
    if (filter.source != null && filter.source!.isNotEmpty) {
      where.add('source = ?');
      args.add(filter.source);
    }
    if (filter.minPrice != null) {
      where.add('price >= ?');
      args.add(filter.minPrice);
    }
    if (filter.maxPrice != null) {
      where.add('price <= ?');
      args.add(filter.maxPrice);
    }
    if (filter.minRating != null) {
      where.add('averageRating >= ?');
      args.add(filter.minRating);
    }
    if (filter.maxRating != null) {
      where.add('averageRating <= ?');
      args.add(filter.maxRating);
    }

    final maps = await db.query('Products',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args);
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  // ──── Favorites ────
  Future<List<FavoriteItem>> getAllFavorites() async {
    final db = await database;
    final maps = await db.query('Favorites', orderBy: 'savedAt DESC');
    return maps.map((m) => FavoriteItem.fromMap(m)).toList();
  }

  Future<FavoriteItem?> getFavoriteByIdentifier(String identifier) async {
    final db = await database;
    final maps = await db.query('Favorites',
        where: 'productIdentifier = ?', whereArgs: [identifier]);
    return maps.isEmpty ? null : FavoriteItem.fromMap(maps.first);
  }

  Future<int> saveFavorite(FavoriteItem item) async {
    final db = await database;
    return db.insert('Favorites', item.toMap());
  }

  Future<int> deleteFavoriteByIdentifier(String identifier) async {
    final db = await database;
    return db.delete('Favorites',
        where: 'productIdentifier = ?', whereArgs: [identifier]);
  }

  Future<int> getFavoriteCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM Favorites');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ──── Price History ────
  Future<List<PriceHistoryEntry>> getPriceHistoryByIdentifier(
      String identifier) async {
    final db = await database;
    final maps = await db.query('PriceHistory',
        where: 'productIdentifier = ?',
        whereArgs: [identifier],
        orderBy: 'recordedAt DESC');
    return maps.map((m) => PriceHistoryEntry.fromMap(m)).toList();
  }

  Future<int> savePriceHistory(PriceHistoryEntry entry) async {
    final db = await database;
    return db.insert('PriceHistory', entry.toMap());
  }

  Future<void> purgePriceHistoryOlderThan(Duration duration) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(duration).toIso8601String();
    await db.delete('PriceHistory',
        where: 'recordedAt < ?', whereArgs: [cutoff]);
  }

  // ──── Product Alerts ────
  Future<List<ProductAlertEntry>> getActiveAlerts() async {
    final db = await database;
    final maps =
        await db.query('ProductAlerts', where: 'isActive = 1');
    return maps.map((m) => ProductAlertEntry.fromMap(m)).toList();
  }

  Future<List<ProductAlertEntry>> getAllAlerts() async {
    final db = await database;
    final maps =
        await db.query('ProductAlerts', orderBy: 'createdAt DESC');
    return maps.map((m) => ProductAlertEntry.fromMap(m)).toList();
  }

  Future<int> saveAlert(ProductAlertEntry entry) async {
    final db = await database;
    if (entry.id != null) {
      return db.update('ProductAlerts', entry.toMap(),
          where: 'id = ?', whereArgs: [entry.id]);
    }
    return db.insert('ProductAlerts', entry.toMap());
  }

  Future<int> deleteAlert(int id) async {
    final db = await database;
    return db.delete('ProductAlerts', where: 'id = ?', whereArgs: [id]);
  }

  // ──── Search Analytics ────
  Future<int> saveSearchAnalytics(SearchAnalyticsEntry entry) async {
    final db = await database;
    return db.insert('SearchAnalytics', entry.toMap());
  }

  Future<List<String>> getPopularSearches(int count) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT query, COUNT(*) as cnt FROM SearchAnalytics 
      GROUP BY query ORDER BY cnt DESC LIMIT ?
    ''', [count]);
    return maps.map((m) => m['query'] as String).toList();
  }

  Future<double> getAverageResponseTime() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT AVG(responseMs) as avg FROM SearchAnalytics');
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> purgeOldAnalytics(Duration duration) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(duration).toIso8601String();
    await db.delete('SearchAnalytics',
        where: 'searchedAt < ?', whereArgs: [cutoff]);
  }
}
