/// Core product entity stored in SQLite
class Product {
  int? id;
  String name;
  String? type;
  String? sku;
  double price;
  int numberOfRatings;
  double averageRating;
  String? source;
  String? description;
  String? imageUrl;
  String? brand;
  String? category;
  DateTime dateAdded;
  bool isFavorite;
  String? productUrl;

  /// Transient — computed at runtime during comparison scoring
  double comparisonScore;

  Product({
    this.id,
    required this.name,
    this.type,
    this.sku,
    this.price = 0.0,
    this.numberOfRatings = 0,
    this.averageRating = 0.0,
    this.source,
    this.description,
    this.imageUrl,
    this.brand,
    this.category,
    DateTime? dateAdded,
    this.isFavorite = false,
    this.productUrl,
    this.comparisonScore = 0.0,
  }) : dateAdded = dateAdded ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'sku': sku,
        'price': price,
        'numberOfRatings': numberOfRatings,
        'averageRating': averageRating,
        'source': source,
        'description': description,
        'imageUrl': imageUrl,
        'brand': brand,
        'category': category,
        'dateAdded': dateAdded.toIso8601String(),
        'isFavorite': isFavorite ? 1 : 0,
        'productUrl': productUrl,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        type: map['type'] as String?,
        sku: map['sku'] as String?,
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        numberOfRatings: (map['numberOfRatings'] as int?) ?? 0,
        averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
        source: map['source'] as String?,
        description: map['description'] as String?,
        imageUrl: map['imageUrl'] as String?,
        brand: map['brand'] as String?,
        category: map['category'] as String?,
        dateAdded: map['dateAdded'] != null
            ? DateTime.tryParse(map['dateAdded'] as String) ?? DateTime.now()
            : DateTime.now(),
        isFavorite: (map['isFavorite'] as int?) == 1,
        productUrl: map['productUrl'] as String?,
      );

  Product copyWith({
    int? id,
    String? name,
    String? type,
    String? sku,
    double? price,
    int? numberOfRatings,
    double? averageRating,
    String? source,
    String? description,
    String? imageUrl,
    String? brand,
    String? category,
    DateTime? dateAdded,
    bool? isFavorite,
    String? productUrl,
    double? comparisonScore,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        sku: sku ?? this.sku,
        price: price ?? this.price,
        numberOfRatings: numberOfRatings ?? this.numberOfRatings,
        averageRating: averageRating ?? this.averageRating,
        source: source ?? this.source,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        brand: brand ?? this.brand,
        category: category ?? this.category,
        dateAdded: dateAdded ?? this.dateAdded,
        isFavorite: isFavorite ?? this.isFavorite,
        productUrl: productUrl ?? this.productUrl,
        comparisonScore: comparisonScore ?? this.comparisonScore,
      );

  @override
  String toString() => 'Product($name, ₹$price, $source)';
}
