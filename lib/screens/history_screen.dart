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
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              String dateKey = sortedDates[index];
              DateTime date = DateTime.parse(dateKey);
              String formattedDate = DateFormat('EEEE, MMM d').format(date);
              double dailyTotal = dailyTotals[dateKey]!;
              List<MealSession> sessions = groupedSessions[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formattedDate.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary)),
                            Text('₹${dailyTotal.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryDark)),
                          ],
                        ),
                        if (sessions.any((s) => !s.isPaid))
                          TextButton(
                            onPressed: () => _showPaidConfirm(context, provider, date),
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('PAID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                  ...sessions.map((session) => _buildSessionCard(session)),
                  const SizedBox(height: 16),
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

  Widget _buildSessionCard(MealSession session) {
    String timeStr = DateFormat('h:mm a').format(session.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.restaurant_rounded, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.itemSummary ?? 'Meal logged at $timeStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (session.note != null && session.note!.isNotEmpty)
                  Text(session.note!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                if (session.itemSummary != null)
                   Text('at $timeStr', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${session.totalCost.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(session.isPaid ? 'PAID' : 'UNPAID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: session.isPaid ? AppTheme.accentColor : AppTheme.errorColor)),
            ],
          ),
        ],
      ),
    );
  }
}
