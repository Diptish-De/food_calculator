class MealSession {
  final int? id;
  final DateTime timestamp;
  final double totalCost;
  final String? note;
  final bool isPaid;
  final String? itemSummary;
  final DateTime? paidOn;

  MealSession({
    this.id,
    required this.timestamp,
    required this.totalCost,
    this.note,
    this.isPaid = false,
    this.itemSummary,
    this.paidOn,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'total_cost': totalCost,
      'note': note,
      'is_paid': isPaid ? 1 : 0,
      'paid_on': paidOn?.toIso8601String(),
    };
  }

  factory MealSession.fromMap(Map<String, dynamic> map) {
    return MealSession(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      totalCost: (map['total_cost'] as num).toDouble(),
      note: map['note'],
      isPaid: map['is_paid'] == 1,
      itemSummary: map['item_summary'],
      paidOn: map['paid_on'] != null ? DateTime.parse(map['paid_on']) : null,
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
