import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../utils/app_theme.dart';
import '../models/meal_session.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Meal History', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Consumer<FoodProvider>(
        builder: (context, provider, child) {
          if (provider.sessions.isEmpty) {
            return const Center(child: Text('No logs yet.', style: TextStyle(color: AppTheme.textSecondary)));
          }

          // Group sessions by date
          Map<String, List<MealSession>> groupedSessions = {};
          Map<String, double> dailyTotals = {};

          for (var session in provider.sessions) {
            String dateKey = DateFormat('yyyy-MM-dd').format(session.timestamp);
            if (!groupedSessions.containsKey(dateKey)) {
              groupedSessions[dateKey] = [];
              dailyTotals[dateKey] = 0;
            }
            groupedSessions[dateKey]!.add(session);
            dailyTotals[dateKey] = dailyTotals[dateKey]! + session.totalCost;
          }

          List<String> sortedDates = groupedSessions.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.headerGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                    ],
                  ),
                  child: Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL DUES', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          Text('Unpaid till today', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                      const Spacer(),
                      Text('₹${provider.dueTotal.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    ],
                  ),
                );
              }

              String dateKey = sortedDates[index - 1];
              DateTime date = DateTime.parse(dateKey);
              String formattedDate = DateFormat('EEEE, MMM d').format(date);
              double dailyTotal = dailyTotals[dateKey]!;
              List<MealSession> sessions = groupedSessions[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formattedDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        if (sessions.any((s) => !s.isPaid))
                          GestureDetector(
                            onTap: () => _showPaidConfirm(context, provider, date),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('PAID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...sessions.map((session) => _buildCompactSessionCard(session)),
                  const SizedBox(height: 4),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showPaidConfirm(BuildContext context, FoodProvider provider, DateTime date) {
    String formattedDate = DateFormat('MMM d').format(date);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: Text('Mark all meals on or before $formattedDate as PAID?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              provider.markAsPaidUpToDate(date);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('YES, PAID', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSessionCard(MealSession session) {
    String timeStr = DateFormat('h:mm a').format(session.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.itemSummary ?? 'Meal logged', 
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  session.isPaid 
                    ? (session.paidOn != null ? 'Paid on ${DateFormat('MMM d').format(session.paidOn!)}' : 'PAID')
                    : 'UNPAID • at $timeStr',
                  style: TextStyle(
                    fontSize: 10, 
                    color: session.isPaid ? AppTheme.primaryColor : AppTheme.errorColor,
                    fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${session.totalCost.toInt()}', 
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryDark)
          ),
        ],
      ),
    );
  }
}
}
