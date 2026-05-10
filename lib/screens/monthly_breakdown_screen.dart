import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../utils/app_theme.dart';
import '../models/meal_session.dart';
import 'package:intl/intl.dart';

class MonthlyBreakdownScreen extends StatelessWidget {
  const MonthlyBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Monthly Overview', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Consumer<FoodProvider>(
        builder: (context, provider, child) {
          if (provider.sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text('No data yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  SizedBox(height: 4),
                  Text('Start logging meals to see your monthly breakdown.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          // Group sessions by month
          final months = _groupByMonth(provider.sessions);
          final sortedKeys = months.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final monthKey = sortedKeys[index];
              final data = months[monthKey]!;
              return _MonthCard(monthKey: monthKey, data: data);
            },
          );
        },
      ),
    );
  }

  Map<String, _MonthData> _groupByMonth(List<MealSession> sessions) {
    final Map<String, _MonthData> result = {};

    for (var session in sessions) {
      final key = DateFormat('yyyy-MM').format(session.timestamp);
      if (!result.containsKey(key)) {
        result[key] = _MonthData();
      }
      result[key]!.totalSpent += session.totalCost;
      result[key]!.totalMeals++;
      if (session.isPaid) {
        result[key]!.totalPaid += session.totalCost;
      } else {
        result[key]!.totalDue += session.totalCost;
      }
      result[key]!.sessions.add(session);
    }

    return result;
  }
}

class _MonthData {
  double totalSpent = 0;
  double totalPaid = 0;
  double totalDue = 0;
  int totalMeals = 0;
  List<MealSession> sessions = [];
}

class _MonthCard extends StatefulWidget {
  final String monthKey;
  final _MonthData data;

  const _MonthCard({required this.monthKey, required this.data});

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Auto-expand current month
    final now = DateFormat('yyyy-MM').format(DateTime.now());
    if (widget.monthKey == now) _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse('${widget.monthKey}-01');
    final monthLabel = DateFormat('MMMM yyyy').format(date);
    final data = widget.data;
    final isCurrentMonth = widget.monthKey == DateFormat('yyyy-MM').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCurrentMonth 
          ? Border.all(color: AppTheme.primaryColor, width: 2)
          : Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header — always visible
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrentMonth 
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded, 
                          color: isCurrentMonth ? AppTheme.primaryColor : AppTheme.textSecondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(monthLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                if (isCurrentMonth) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('NOW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('${data.totalMeals} meals logged', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        '₹${data.totalSpent.toInt()}', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),

                  // Stats row
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMiniStat('Paid', '₹${data.totalPaid.toInt()}', AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      _buildMiniStat('Due', '₹${data.totalDue.toInt()}', data.totalDue > 0 ? AppTheme.errorColor : AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      _buildMiniStat('Avg/Day', '₹${data.totalMeals > 0 ? (data.totalSpent / data.totalMeals).toInt() : 0}', AppTheme.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded — daily breakdown
          if (_expanded) ...[
            const Divider(height: 1),
            _buildDailyBreakdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBreakdown() {
    // Group by day
    final Map<String, List<MealSession>> daily = {};
    final Map<String, double> dailyTotals = {};

    for (var s in widget.data.sessions) {
      final dayKey = DateFormat('yyyy-MM-dd').format(s.timestamp);
      daily.putIfAbsent(dayKey, () => []);
      daily[dayKey]!.add(s);
      dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + s.totalCost;
    }

    final sortedDays = daily.keys.toList()..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: sortedDays.map((dayKey) {
          final date = DateTime.parse(dayKey);
          final dayLabel = DateFormat('EEE, MMM d').format(date);
          final total = dailyTotals[dayKey]!;
          final sessions = daily[dayKey]!;
          final allPaid = sessions.every((s) => s.isPaid);

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 32,
                  decoration: BoxDecoration(
                    color: allPaid ? AppTheme.primaryColor : AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dayLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(
                        sessions.map((s) => s.itemSummary ?? '').where((s) => s.isNotEmpty).join(' | '),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${total.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryDark)),
                    Text(
                      allPaid ? 'PAID' : 'UNPAID', 
                      style: TextStyle(
                        fontSize: 9, 
                        fontWeight: FontWeight.bold, 
                        color: allPaid ? AppTheme.primaryColor : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
