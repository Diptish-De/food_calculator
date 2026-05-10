import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/food_item.dart';
import '../models/meal_session.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  List<FoodItem> _foodItems = [];
  List<MealSession> _sessions = [];
  
  // Current session building state
  Map<int, int> _cart = {}; // foodItemId -> quantity

  // Stats
  double _todayTotal = 0;
  double _monthTotal = 0;
  double _dueTotal = 0;
  double _monthlyBudget = 3000; // Default budget
  String _userName = 'User';

  DateTime _selectedLoggingDate = DateTime.now();

  List<FoodItem> get foodItems => _foodItems;
  List<MealSession> get sessions => _sessions;
  Map<int, int> get cart => _cart;
  DateTime get selectedLoggingDate => _selectedLoggingDate;
  
  double get todayTotal => _todayTotal;
  double get monthTotal => _monthTotal;
  double get dueTotal => _dueTotal;
  double get monthlyBudget => _monthlyBudget;
  double get budgetRemaining => _monthlyBudget - _monthTotal;
  String get userName => _userName;

  double get cartTotal {
    double total = 0;
    _cart.forEach((id, qty) {
      final item = _foodItems.firstWhere((element) => element.id == id);
      total += item.price * qty;
    });
    return total;
  }

  int get cartCount {
    int count = 0;
    _cart.forEach((id, qty) => count += qty);
    return count;
  }

  Future<void> loadInitialData() async {
    // Load saved user name
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'User';

    if (kIsWeb) {
      // Mock data for Web preview
      _foodItems = [
        FoodItem(id: 1, name: 'Full Bhat', category: 'Main', price: 20.0, icon: 'rice'),
        FoodItem(id: 2, name: 'Half Bhat', category: 'Main', price: 10.0, icon: 'rice'),
        FoodItem(id: 3, name: 'Ruti', category: 'Main', price: 4.0, icon: 'bread'),
        FoodItem(id: 4, name: 'Dal', category: 'Curry', price: 5.0, icon: 'vegetable'),
        FoodItem(id: 5, name: 'Sabji', category: 'Curry', price: 5.0, icon: 'vegetable'),
        FoodItem(id: 6, name: 'Dim Bhaja', category: 'Egg', price: 12.0, icon: 'egg'),
        FoodItem(id: 7, name: 'Dim Seddho', category: 'Egg', price: 10.0, icon: 'egg'),
        FoodItem(id: 8, name: 'Dim Curry', category: 'Egg', price: 15.0, icon: 'egg'),
        FoodItem(id: 9, name: 'Mach', category: 'Non-Veg', price: 30.0, icon: 'fish'),
        FoodItem(id: 10, name: 'Alu Bhate', category: 'Side', price: 5.0, icon: 'potato'),
        FoodItem(id: 11, name: 'Alu Dom', category: 'Curry', price: 10.0, icon: 'potato'),
        FoodItem(id: 12, name: 'Soyabean', category: 'Curry', price: 7.0, icon: 'vegetable'),
      ];
      notifyListeners();
      return;
    }

    final items = await _dbHelper.getFoodItems();
    _foodItems = items.map((m) => FoodItem.fromMap(m)).toList();
    
    final sessionData = await _dbHelper.getSessions();
    _sessions = sessionData.map((m) => MealSession.fromMap(m)).toList();
    
    _calculateStats();
    // Schedule/cancel notifications based on dues
    NotificationService.scheduleWeeklyReminders(_dueTotal);
    notifyListeners();
  }

  void _calculateStats() {
    final now = DateTime.now();
    _todayTotal = 0;
    _monthTotal = 0;
    _dueTotal = 0;
    
    for (var session in _sessions) {
      if (session.timestamp.year == now.year &&
          session.timestamp.month == now.month) {
        _monthTotal += session.totalCost;
        if (session.timestamp.day == now.day) {
          _todayTotal += session.totalCost;
        }
      }
      
      if (!session.isPaid) {
        _dueTotal += session.totalCost;
      }
    }
  }

  Future<void> markAsPaid() async {
    await _dbHelper.markAllAsPaid();
    await loadInitialData();
    // Dues cleared — cancel reminders
    NotificationService.cancelAll();
  }

  Future<void> markAsPaidUpToDate(DateTime date) async {
    if (kIsWeb) {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final now = DateTime.now();
      for (int i = 0; i < _sessions.length; i++) {
        final sessionDateKey = DateFormat('yyyy-MM-dd').format(_sessions[i].timestamp);
        if (sessionDateKey.compareTo(dateKey) <= 0) {
          _sessions[i] = MealSession(
            id: _sessions[i].id,
            timestamp: _sessions[i].timestamp,
            totalCost: _sessions[i].totalCost,
            isPaid: true,
            itemSummary: _sessions[i].itemSummary,
            note: _sessions[i].note,
            paidOn: now,
          );
        }
      }
      _calculateStats();
      notifyListeners();
      return;
    }
    await _dbHelper.markAsPaidUpToDate(date);
    await loadInitialData();
  }

  Future<void> addFoodItem(FoodItem item) async {
    if (kIsWeb) {
      final newItem = FoodItem(
        id: _foodItems.length + 1,
        name: item.name,
        category: item.category,
        price: item.price,
        icon: item.icon,
      );
      _foodItems.add(newItem);
      notifyListeners();
      return;
    }
    await _dbHelper.insertFoodItem(item);
    await loadInitialData();
  }

  Future<void> updateFoodItem(FoodItem item) async {
    if (kIsWeb) {
      final index = _foodItems.indexWhere((f) => f.id == item.id);
      if (index != -1) {
        _foodItems[index] = item;
        notifyListeners();
      }
      return;
    }
    await _dbHelper.updateFoodItem(item);
    await loadInitialData();
  }

  Future<void> deleteFoodItem(int id) async {
    if (kIsWeb) {
      _foodItems.removeWhere((item) => item.id == id);
      notifyListeners();
      return;
    }
    await _dbHelper.deleteFoodItem(id);
    await loadInitialData();
  }

  void addCombo(Map<int, int> items) {
    items.forEach((id, qty) {
      _cart[id] = (_cart[id] ?? 0) + qty;
    });
    notifyListeners();
  }

  void addToCart(int foodItemId) {
    if (_cart.containsKey(foodItemId)) {
      _cart[foodItemId] = _cart[foodItemId]! + 1;
    } else {
      _cart[foodItemId] = 1;
    }
    notifyListeners();
  }

  void removeFromCart(int foodItemId) {
    if (_cart.containsKey(foodItemId)) {
      if (_cart[foodItemId] == 1) {
        _cart.remove(foodItemId);
      } else {
        _cart[foodItemId] = _cart[foodItemId]! - 1;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _selectedLoggingDate = DateTime.now();
    notifyListeners();
  }

  void setLoggingDate(DateTime date) {
    _selectedLoggingDate = date;
    notifyListeners();
  }

  void updateBudget(double amount) {
    _monthlyBudget = amount;
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    notifyListeners();
  }

  void reorderFoodItems(int oldIndex, int newIndex) {
    final item = _foodItems.removeAt(oldIndex);
    _foodItems.insert(newIndex, item);
    notifyListeners();
  }

  Map<String, int> getTopItems() {
    final Map<String, int> counts = {};
    for (var session in _sessions) {
      if (session.itemSummary != null && session.itemSummary!.isNotEmpty) {
        // DB format: "Ruti x2, Dim Jhol x1" — name first, then xQty
        final parts = session.itemSummary!.split(', ');
        for (var part in parts) {
          final trimmed = part.trim();
          final match = RegExp(r'(.+?)\s*x(\d+)').firstMatch(trimmed);
          if (match != null) {
            final name = match.group(1)!.trim();
            final qty = int.parse(match.group(2)!);
            counts[name] = (counts[name] ?? 0) + qty;
          }
        }
      }
    }
    // Sort and take top 3
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sorted.take(3));
  }

  Future<void> clearAllSessions() async {
    if (kIsWeb) {
      _sessions.clear();
      _todayTotal = 0;
      _monthTotal = 0;
      _dueTotal = 0;
    } else {
      await _dbHelper.deleteAllSessions();
      await loadInitialData();
    }
    notifyListeners();
  }

  Future<void> fullReset() async {
    if (kIsWeb) {
      _sessions.clear();
      _foodItems.clear();
      _todayTotal = 0;
      _monthTotal = 0;
      _dueTotal = 0;
    } else {
      await _dbHelper.fullReset();
      await loadInitialData();
    }
    notifyListeners();
  }

  Future<void> saveSession({String? note}) async {
    if (_cart.isEmpty) return;
    if (kIsWeb) {
      // Find if a session for this date already exists in our mock list
      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedLoggingDate);
      int existingIndex = _sessions.indexWhere((s) => 
        DateFormat('yyyy-MM-dd').format(s.timestamp) == dateKey && !s.isPaid
      );

      if (existingIndex != -1) {
        // Merge with existing mock session
        final existing = _sessions[existingIndex];
        final newItems = _cart.entries.map((e) {
          final item = _foodItems.firstWhere((f) => f.id == e.key);
          return '${item.name} x${e.value}';
        }).join(', ');
        
        _sessions[existingIndex] = MealSession(
          id: existing.id,
          timestamp: existing.timestamp,
          totalCost: existing.totalCost + cartTotal,
          isPaid: false,
          itemSummary: '${existing.itemSummary}, $newItems',
        );
      } else {
        // Create new mock session
        final mockSession = MealSession(
          id: _sessions.length + 1,
          timestamp: _selectedLoggingDate,
          totalCost: cartTotal,
          isPaid: false,
          itemSummary: _cart.entries.map((e) {
            final item = _foodItems.firstWhere((f) => f.id == e.key);
            return '${item.name} x${e.value}';
          }).join(', '),
        );
        _sessions.add(mockSession);
        // Keep it sorted: latest date first
        _sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      
      _calculateStats();
      clearCart();
      return;
    }

    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedLoggingDate);
    
    // Check if a session already exists for this date
    int? existingSessionId;
    for (var s in _sessions) {
      if (DateFormat('yyyy-MM-dd').format(s.timestamp) == dateKey && !s.isPaid) {
        existingSessionId = s.id;
        break;
      }
    }

    if (existingSessionId != null) {
      // Update existing session
      final List<SessionItem> items = [];
      _cart.forEach((id, qty) {
        final foodItem = _foodItems.firstWhere((element) => element.id == id);
        items.add(SessionItem(
          sessionId: existingSessionId!,
          foodItemId: id,
          quantity: qty,
          priceAtTime: foodItem.price,
        ));
      });
      await _dbHelper.updateSession(existingSessionId, cartTotal, items);
    } else {
      // Create new session
      final session = MealSession(
        timestamp: _selectedLoggingDate,
        totalCost: cartTotal,
        note: note,
      );

      final List<SessionItem> items = [];
      _cart.forEach((id, qty) {
        final foodItem = _foodItems.firstWhere((element) => element.id == id);
        items.add(SessionItem(
          sessionId: 0,
          foodItemId: id,
          quantity: qty,
          priceAtTime: foodItem.price,
        ));
      });

      await _dbHelper.insertSession(session, items);
    }
    
    clearCart();
    await loadInitialData();
  }
}
