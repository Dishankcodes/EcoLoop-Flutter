class CartItem {
  final String id;
  final String title;
  final double price;
  final int quantity;
  final String condition;
  final String category;
  final String seller;
  final String location;
  final String image;
  final int availableQuantity;

  const CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    this.condition = '',
    this.category = '',
    this.seller = '',
    this.location = '',
    this.image = '',
    this.availableQuantity = 99,
  });

  CartItem copyWith({
    String? id,
    String? title,
    double? price,
    int? quantity,
    String? condition,
    String? category,
    String? seller,
    String? location,
    String? image,
    int? availableQuantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      category: category ?? this.category,
      seller: seller ?? this.seller,
      location: location ?? this.location,
      image: image ?? this.image,
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }

  factory CartItem.fromProduct(Map<String, dynamic> product, {int quantity = 1}) {
    final rawPrice = product['price'];
    double price;
    if (rawPrice is num) {
      price = rawPrice.toDouble();
    } else {
      price = double.tryParse(
            rawPrice
                    ?.toString()
                    .replaceAll('₹', '')
                    .replaceAll(',', '')
                    .trim() ??
                '0',
          ) ??
          0;
    }

    final rawAvailable = product['availableQuantity'];
    final available = rawAvailable is num
        ? rawAvailable.toInt()
        : int.tryParse(rawAvailable?.toString() ?? '') ?? 99;

    final images = product['images'];
    String image = product['image']?.toString() ?? '';
    if (images is List && images.isNotEmpty) {
      image = images.first.toString();
    }

    return CartItem(
      id: (product['productId'] ?? product['id'] ?? '').toString(),
      title: product['title']?.toString() ?? 'Product',
      price: price,
      quantity: quantity.clamp(1, available > 0 ? available : 1).toInt(),
      condition: product['condition']?.toString() ?? '',
      category: product['category']?.toString() ?? '',
      seller: product['seller']?.toString() ?? '',
      location: product['location']?.toString() ?? '',
      image: image,
      availableQuantity: available > 0 ? available : 1,
    );
  }
}
