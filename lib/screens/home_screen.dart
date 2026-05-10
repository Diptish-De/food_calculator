import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
// glass_container available if needed
import '../utils/app_theme.dart';
import 'settings_screen.dart';
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
                              IconButton(
                                icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
                                onPressed: _showAccountSummary,
                              ),
                              Text('Food Tracker', style: AppTheme.lightTheme.appBarTheme.titleTextStyle),
                              IconButton(
                                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                                onPressed: () {
                                  final hasDues = provider.dueTotal > 0;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    backgroundColor: hasDues ? AppTheme.errorColor : AppTheme.primaryColor,
                                    content: Text(hasDues ? '⚠️ Reminder: You have ₹${provider.dueTotal.toInt()} in unpaid dues!' : '🎉 All clear! You have no unpaid dues.'),
                                  ));
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildCircularProgress(provider),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem('Month', '₹${provider.monthTotal.toInt()}', 'Total'),
                                _buildStatItem('Due', '₹${provider.dueTotal.toInt()}', 'Unpaid', isWarning: provider.dueTotal > 0),
                                _buildStatItem(
                                  'Budget', 
                                  '₹${provider.budgetRemaining.toInt()}', 
                                  'Left', 
                                  isWarning: provider.budgetRemaining < 500,
                                  onTap: () => _showBudgetDialog(context, provider),
                                ),
                              ],
                            ),
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
                                  Icon(_getIcon(item.icon), color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary, size: 24),
                                  const SizedBox(height: 8),
                                  Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary)),
                                  Text('₹${item.price.toInt()}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  if (isSelected) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () => provider.removeFromCart(item.id!),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                            child: const Icon(Icons.remove, size: 14, color: AppTheme.primaryColor),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, fontSize: 14)),
                                        ),
                                        GestureDetector(
                                          onTap: () => provider.addToCart(item.id!),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                                            child: const Icon(Icons.add, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('SEE STATS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, FoodProvider provider) {
    final controller = TextEditingController(text: provider.monthlyBudget.toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Set Budget Limit (₹)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                provider.updateBudget(val);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('SET BUDGET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAccountSummary() {
    final provider = context.read<FoodProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Account Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow('Total Logs', '${provider.sessions.length} meals'),
            _summaryRow('Monthly Spend', '₹${provider.monthTotal.toInt()}'),
            _summaryRow('Current Dues', '₹${provider.dueTotal.toInt()}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  void _showPopularMeals() {
    final provider = context.read<FoodProvider>();
    final topItems = provider.getTopItems();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            const Text('Your Favorites'),
          ],
        ),
        content: topItems.isEmpty 
          ? const Text('Log some meals first to see your favorites!')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: topItems.entries.map((e) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text('${topItems.keys.toList().indexOf(e.key) + 1}', 
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
                title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('${e.value} times', style: const TextStyle(color: AppTheme.textSecondary)),
              )).toList(),
            ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('COOL')),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String sub, {bool isWarning = false, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: isWarning ? AppTheme.warningColor : Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w500)),
          ],
        ),
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
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded), 
              onPressed: _showPopularMeals,
            ),
            IconButton(icon: const Icon(Icons.history_rounded), onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
            }),
            const SizedBox(width: 40), // Space for FAB
            IconButton(icon: const Icon(Icons.receipt_long_outlined), onPressed: () {
               _generateAndShareBill();
            }),
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
          ],
        ),
      ),
    );
  }

  void _generateAndShareBill() {
    final provider = context.read<FoodProvider>();
    final unpaidSessions = provider.sessions.where((s) => !s.isPaid).toList();
    
    if (unpaidSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No unpaid dues to share!')));
      return;
    }

    String billText = "📄 *HOSTEL FOOD BILL*\n";
    billText += "--------------------------\n";
    
    double total = 0;
    for (var session in unpaidSessions) {
      final date = "${session.timestamp.day}/${session.timestamp.month}";
      final summary = session.itemSummary ?? "Items logged";
      billText += "• $date: ₹${session.totalCost.toInt()} ($summary)\n";
      total += session.totalCost;
    }
    
    billText += "--------------------------\n";
    billText += "💰 *TOTAL DUE: ₹${total.toInt()}*\n";
    billText += "--------------------------\n";
    billText += "Generated via Food Tracker";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Unpaid Bill'),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: SelectableText(billText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: billText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill copied to clipboard! Paste it in WhatsApp.')));
            },
            icon: const Icon(Icons.copy_rounded, color: Colors.white),
            label: const Text('COPY & SEND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
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
