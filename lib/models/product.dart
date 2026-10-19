/// Immutable product model for the thrift shop app.
///
/// All fields are `final` and the class provides a `const` constructor.
/// The optional `copyWith` method can be used to create a modified copy
/// without mutating the original instance.
class Product {
  final String id;
  final String title;
  final String brand; // 'UNIQLO' | 'MUJI' | 'ZARA' | 'Local Brand'
  final String size; // 'S' | 'M' | 'L' | 'XL'
  final String condition; // '70%' | '80%' | '90%' | 'Like New'
  final int price; // IDR, integer, no decimals
  final String imageUrl; // empty string for now
  final List<String> tags; // lowercase keywords
  final DateTime createdAt;
  final int popularity; // higher = more popular

  const Product({
    required this.id,
    required this.title,
    required this.brand,
    required this.size,
    required this.condition,
    required this.price,
    this.imageUrl = '',
    required this.tags,
    required this.createdAt,
    required this.popularity,
  });

  Product copyWith({
    String? id,
    String? title,
    String? brand,
    String? size,
    String? condition,
    int? price,
    String? imageUrl,
    List<String>? tags,
    DateTime? createdAt,
    int? popularity,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? List<String>.from(this.tags),
      createdAt: createdAt ?? this.createdAt,
      popularity: popularity ?? this.popularity,
    );
  }
}
