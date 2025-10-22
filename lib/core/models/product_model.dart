/// Immutable Product model representing a product in the store
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.discount = 0.0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.category = '',
    this.brand = '',
    this.isAvailable = true,
    this.features = const [],
  });

  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final double discount;
  final double rating;
  final int reviewCount;
  final String category;
  final String brand;
  final bool isAvailable;
  final List<String> features;

  /// Factory constructor to create Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true,
      features:
          (json['features'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  /// Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'discount': discount,
      'rating': rating,
      'reviewCount': reviewCount,
      'category': category,
      'brand': brand,
      'isAvailable': isAvailable,
      'features': features,
    };
  }

  /// Create a copy of this Product with updated fields
  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    double? discount,
    double? rating,
    int? reviewCount,
    String? category,
    String? brand,
    bool? isAvailable,
    List<String>? features,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      discount: discount ?? this.discount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      isAvailable: isAvailable ?? this.isAvailable,
      features: features ?? this.features,
    );
  }

  /// Get discounted price
  double get discountedPrice => price - (price * discount / 100);

  /// Check if product has discount
  bool get hasDiscount => discount > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price)';
  }
}
