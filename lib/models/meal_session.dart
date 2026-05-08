class MealSession {
  final int? id;
  final DateTime timestamp;
  final double totalCost;
  final String? note;
  final bool isPaid;
  final String? itemSummary;

  MealSession({
    this.id,
    required this.timestamp,
    required this.totalCost,
    this.note,
    this.isPaid = false,
    this.itemSummary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'total_cost': totalCost,
      'note': note,
      'is_paid': isPaid ? 1 : 0,
    };
  }

  factory MealSession.fromMap(Map<String, dynamic> map) {
    return MealSession(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      totalCost: map['total_cost'],
      note: map['note'],
      isPaid: map['is_paid'] == 1,
      itemSummary: map['item_summary'],
    );
  }
}

class SessionItem {
  final int? id;
  final int sessionId;
  final int foodItemId;
  final int quantity;
  final double priceAtTime;
  final String foodName; // Joined field for convenience

  SessionItem({
    this.id,
    required this.sessionId,
    required this.foodItemId,
    required this.quantity,
    required this.priceAtTime,
    this.foodName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'food_item_id': foodItemId,
      'quantity': quantity,
      'price_at_time': priceAtTime,
    };
  }

  factory SessionItem.fromMap(Map<String, dynamic> map) {
    return SessionItem(
      id: map['id'],
      sessionId: map['session_id'],
      foodItemId: map['food_item_id'],
      quantity: map['quantity'],
      priceAtTime: map['price_at_time'],
      foodName: map['food_name'] ?? '',
    );
  }
}
