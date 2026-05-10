import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';
import '../models/meal_session.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() => _instance;

  DBHelper._internal();

  Future<Database> get database async {
    if (kIsWeb) throw Exception("Database not supported on Web");
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'food_calculator.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        total_cost REAL NOT NULL,
        note TEXT,
        is_paid INTEGER DEFAULT 0,
        paid_on TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE session_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        food_item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price_at_time REAL NOT NULL,
        FOREIGN KEY (session_id) REFERENCES meal_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (food_item_id) REFERENCES food_items (id)
      )
    ''');

    // Insert initial common food items
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    List<FoodItem> initialItems = [
      FoodItem(name: 'Full Bhat', category: 'Main', price: 20.0),
      FoodItem(name: 'Half Bhat', category: 'Main', price: 10.0),
      FoodItem(name: 'Dim Bhaja', category: 'Egg', price: 12.0),
      FoodItem(name: 'Dim Seddho', category: 'Egg', price: 10.0),
      FoodItem(name: 'Dim Curry', category: 'Egg', price: 15.0),
      FoodItem(name: 'Dal', category: 'Curry', price: 5.0),
      FoodItem(name: 'Sabji', category: 'Curry', price: 5.0),
      FoodItem(name: 'Mach', category: 'Non-Veg', price: 30.0),
      FoodItem(name: 'Alu Bhate', category: 'Side', price: 5.0),
      FoodItem(name: 'Ruti', category: 'Main', price: 4.0),
      FoodItem(name: 'Soyabean', category: 'Curry', price: 7.0),
      FoodItem(name: 'Alu Dom', category: 'Curry', price: 10.0),
    ];

    for (var item in initialItems) {
      await db.insert('food_items', item.toMap());
    }
  }

  // Generic CRUD operations can be added here as needed
  Future<List<Map<String, dynamic>>> getFoodItems() async {
    Database db = await database;
    return await db.query('food_items');
  }

  Future<int> insertSession(MealSession session, List<SessionItem> items) async {
    Database db = await database;
    return await db.transaction((txn) async {
      int sessionId = await txn.insert('meal_sessions', session.toMap());
      for (var item in items) {
        await txn.insert('session_items', {
          'session_id': sessionId,
          'food_item_id': item.foodItemId,
          'quantity': item.quantity,
          'price_at_time': item.priceAtTime,
        });
      }
      return sessionId;
    });
  }

  Future<void> updateSession(int sessionId, double additionalCost, List<SessionItem> newItems) async {
    Database db = await database;
    await db.transaction((txn) async {
      // Update total cost
      await txn.rawUpdate(
        'UPDATE meal_sessions SET total_cost = total_cost + ? WHERE id = ?',
        [additionalCost, sessionId]
      );
      
      // Update items (if same food exists, increase quantity, else insert)
      for (var item in newItems) {
        final existing = await txn.query('session_items', 
          where: 'session_id = ? AND food_item_id = ?', 
          whereArgs: [sessionId, item.foodItemId]);
        
        if (existing.isNotEmpty) {
          await txn.rawUpdate(
            'UPDATE session_items SET quantity = quantity + ? WHERE id = ?',
            [item.quantity, existing.first['id']]
          );
        } else {
          await txn.insert('session_items', {
            'session_id': sessionId,
            'food_item_id': item.foodItemId,
            'quantity': item.quantity,
            'price_at_time': item.priceAtTime,
          });
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT ms.*, 
      (SELECT GROUP_CONCAT(fi.name || ' x' || si.quantity, ', ') 
       FROM session_items si 
       JOIN food_items fi ON si.food_item_id = fi.id 
       WHERE si.session_id = ms.id) as item_summary
      FROM meal_sessions ms 
      ORDER BY ms.timestamp DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getSessionItems(int sessionId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT si.*, fi.name as food_name 
      FROM session_items si 
      JOIN food_items fi ON si.food_item_id = fi.id 
      WHERE si.session_id = ?
    ''', [sessionId]);
  }

  Future<void> markAllAsPaid() async {
    Database db = await database;
    String now = DateTime.now().toIso8601String();
    await db.update('meal_sessions', {'is_paid': 1, 'paid_on': now}, where: 'is_paid = 0');
  }

  Future<int> insertFoodItem(FoodItem item) async {
    Database db = await database;
    return await db.insert('food_items', item.toMap());
  }

  Future<int> markAsPaidUpToDate(DateTime date) async {
    final db = await database;
    String dateStr = date.toIso8601String();
    return await db.update(
      'meal_sessions',
      {'is_paid': 1, 'paid_on': DateTime.now().toIso8601String()},
      where: 'timestamp <= ? AND is_paid = 0',
      whereArgs: [dateStr],
    );
  }

  Future<void> deleteAllSessions() async {
    final db = await database;
    await db.delete('session_items');
    await db.delete('meal_sessions');
  }

  Future<void> fullReset() async {
    final db = await database;
    await db.delete('session_items');
    await db.delete('meal_sessions');
    await db.delete('food_items');
  }

  Future<int> updateFoodItem(FoodItem item) async {
    Database db = await database;
    return await db.update(
      'food_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteFoodItem(int id) async {
    Database db = await database;
    return await db.delete(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
