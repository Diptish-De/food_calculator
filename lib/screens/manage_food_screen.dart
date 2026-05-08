import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../utils/app_theme.dart';

class ManageFoodScreen extends StatefulWidget {
  const ManageFoodScreen({super.key});

  @override
  State<ManageFoodScreen> createState() => _ManageFoodScreenState();
}

class _ManageFoodScreenState extends State<ManageFoodScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedIcon = 'fastfood';

  final List<Map<String, dynamic>> _icons = [
    {'name': 'bread', 'icon': Icons.bakery_dining_rounded},
    {'name': 'egg', 'icon': Icons.egg_rounded},
    {'name': 'potato', 'icon': Icons.grass_rounded},
    {'name': 'vegetable', 'icon': Icons.set_meal_rounded},
    {'name': 'coffee', 'icon': Icons.coffee_rounded},
    {'name': 'fastfood', 'icon': Icons.fastfood_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Food Items', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Consumer<FoodProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: provider.foodItems.length,
                  itemBuilder: (context, index) {
                    final item = provider.foodItems[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(_getIcon(item.icon), color: AppTheme.primaryColor),
                      ),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('₹${item.price.toInt()}'),
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ADD NEW ITEM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Item Name (e.g. Paratha)',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Price (₹)',
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _icons.map((i) => GestureDetector(
                        onTap: () => setState(() => _selectedIcon = i['name']),
                        child: CircleAvatar(
                          backgroundColor: _selectedIcon == i['name'] ? AppTheme.primaryColor : AppTheme.backgroundColor,
                          child: Icon(i['icon'], color: _selectedIcon == i['name'] ? Colors.white : AppTheme.textSecondary),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
                            provider.addNewFoodItem(
                              _nameController.text,
                              double.parse(_priceController.text),
                              _selectedIcon,
                            );
                            _nameController.clear();
                            _priceController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item Added!')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('ADD TO LIST', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'bread': return Icons.bakery_dining_rounded;
      case 'egg': return Icons.egg_rounded;
      case 'potato': return Icons.grass_rounded;
      case 'vegetable': return Icons.set_meal_rounded;
      case 'coffee': return Icons.coffee_rounded;
      default: return Icons.fastfood_rounded;
    }
  }
}
