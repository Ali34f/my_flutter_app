class MenuItem {
  final String name;
  final double price;
  final String category;
  final String description;
  final bool isVeg;
  final String imageUrl;
  final bool available;
  final String sizeOrType;
  final String spiceLevel;

  MenuItem({
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.isVeg,
    required this.imageUrl,
    required this.available,
    required this.sizeOrType,
    required this.spiceLevel,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['Name'] ?? json['name'] ?? '', // Handle both "Name" and "name"
      price: _parsePrice(json['price']),
      category: (json['category'] ?? '').toString().trim(),
      description: json['description'] ?? '',
      isVeg: _parseBool(json['isVeg']),
      imageUrl: json['imageUrl'] ?? '',
      available: _parseBool(json['available']),
      sizeOrType: json['size_or_type'] ?? '',
      spiceLevel: (json['spiceLevel'] ?? json['spice_level'] ?? 'mild')
          .toString()
          .trim(),
    );
  }

  // Helper method to parse price (handles "££7.50" format)
  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      // Remove all £ symbols and parse
      String cleanPrice = price.replaceAll(RegExp(r'[£]+'), '');
      return double.tryParse(cleanPrice) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to parse boolean (handles string "true"/"false")
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase().trim() == 'true';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'description': description,
      'isVeg': isVeg,
      'imageUrl': imageUrl,
      'available': available,
      'size_or_type': sizeOrType,
      'spice_level': spiceLevel,
    };
  }
}
