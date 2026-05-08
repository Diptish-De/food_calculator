import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../widgets/glass_container.dart';
import '../utils/app_theme.dart';
import 'history_screen.dart';
import 'manage_food_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<FoodProvider>().loadInitialData());
  }

  void _vibrate() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<FoodProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Vibrant Header with Circular Progress
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                      decoration: BoxDecoration(
                        gradient: AppTheme.headerGradient,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.person_outline, color: Colors.white),
                              Text('Food Tracker', style: AppTheme.lightTheme.appBarTheme.titleTextStyle),
                              const Icon(Icons.notifications_none, color: Colors.white),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildCircularProgress(provider),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              _buildMiniStat('Month', '₹${provider.monthTotal.toInt()}', 'Total'),
                              _buildMiniStat('Due', '₹${provider.dueTotal.toInt()}', 'Unpaid', isWarning: true),
                              _buildMiniStat('Saved', '₹120', 'Target'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Quick Add Section (Horizontal Grid)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Text('LOG MEAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary)),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = provider.foodItems[index];
                          final qty = provider.cart[item.id] ?? 0;
                          final isSelected = qty > 0;

                          return GestureDetector(
                            onTap: () {
                              _vibrate();
                              provider.addToCart(item.id!);
                            },
                            onLongPress: () {
                              if (qty > 0) {
                                _vibrate();
                                provider.removeFromCart(item.id!);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                                ],
                                border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.transparent, width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_getIcon(item.icon), size: 24, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary),
                                  const SizedBox(height: 4),
                                  Text(item.name, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                                  Text('₹${item.price.toInt()}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                  if (qty > 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(10)),
                                      child: Text('$qty', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ).animate().scale(),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: (index * 20).ms);
                        },
                        childCount: provider.foodItems.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // 3. Floating Bottom Total Bar
              if (provider.cartCount > 0)
                Positioned(
                  bottom: 100,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${provider.cartCount} ITEMS for ${DateFormat('MMM d').format(provider.selectedLoggingDate)}', 
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)
                            ),
                            Text('₹${provider.cartTotal.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () {
                            _vibrate();
                            provider.clearCart();
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.calendar_month, color: Colors.white70),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: provider.selectedLoggingDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) provider.setLoggingDate(date);
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _vibrate();
                            provider.saveSession();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 1, curve: Curves.easeOutBack),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ManageFoodScreen()));
        },
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildCircularProgress(FoodProvider provider) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 15),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simplified progress ring using CustomPaint would be better, but for now:
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Today Spend', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text('₹${provider.todayTotal.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text('SEE STATS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, String sub, {bool isWarning = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: isWarning ? AppTheme.warningColor : Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.book_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.history), onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
            }),
            const SizedBox(width: 40), // Space for FAB
            IconButton(icon: const Icon(Icons.account_balance_wallet_outlined), onPressed: () {
               _showPaymentDialog();
            }),
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => ManageFoodScreen()));
            }),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Dues?'),
        content: Text('Total due: ₹${context.read<FoodProvider>().dueTotal.toInt()}\nHave you paid the hostel owner?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              context.read<FoodProvider>().markAsPaid();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('YES, PAID'),
          ),
        ],
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
