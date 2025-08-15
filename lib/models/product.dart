class Product {
  const Product({ required this.id, required this.title, required this.price, required this.image });

  final String id;
  final String title;
  final int price;
  final String image;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'image': image,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      price: map['price'] is int ? map['price'] : int.tryParse(map['price'].toString()) ?? 0,
      image: map['image'] ?? '',
    );
  }
}