class FoodItem {
  final int? id;
  final String name;
  final String category;
  final double price;

  FoodItem({
    this.id,
    required this.name,
    required this.category,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      price: map['price'],
    );
  }
}
