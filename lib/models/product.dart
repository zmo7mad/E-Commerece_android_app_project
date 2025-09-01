class Product {
  const Product({ 
    required this.id, 
    required this.title, 
    required this.price, 
    required this.image,
    this.images,
    this.sellerName,
    this.description,
    this.stockQuantity = 0, // Default to 0 stock
  });

  final String id;
  final String title;
  final int price;
  final String image; // Main/primary image (for backward compatibility)
  final List<String>? images; // Multiple images support
  final String? sellerName;
  final String? description;
  final int stockQuantity; // New field for stock management

  // Computed property to check if item is in stock
  bool get isInStock => stockQuantity > 0;
  
  // Computed property to get stock status text
  String get stockStatusText => isInStock ? 'Available' : 'Out of Stock';
  
  // Computed property to get stock status color
  bool get isOutOfStock => !isInStock;

  // Get all images for the product (primary + additional images)
  List<String> get allImages {
    final List<String> allImages = [image]; // Start with primary image
    if (images != null && images!.isNotEmpty) {
      allImages.addAll(images!);
    }
    return allImages;
  }

  // Get the number of images available
  int get imageCount => allImages.length;

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
      'images': images,
      'sellerName': sellerName,
      'description': description,
      'stockQuantity': stockQuantity, // Include stock in map
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    // Handle images list - convert to List<String> if it exists
    List<String>? imagesList;
    if (map['images'] != null) {
      if (map['images'] is List) {
        imagesList = (map['images'] as List).map((e) => e.toString()).toList();
      } else if (map['images'] is String) {
        // If it's a single string, split by comma (fallback)
        imagesList = map['images'].split(',').map((e) => e.trim()).toList();
      }
    }
    
    return Product(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      price: map['price'] is int ? map['price'] : int.tryParse(map['price'].toString()) ?? 0,
      image: map['image'] ?? '',
      images: imagesList,
      sellerName: map['sellerName']?.toString(),
      description: map['description']?.toString(),
      stockQuantity: map['stockQuantity'] is int ? map['stockQuantity'] : int.tryParse(map['stockQuantity']?.toString() ?? '0') ?? 0, // Parse stock quantity
    );
  }
}