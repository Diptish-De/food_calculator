import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Consumer<FoodProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection('Financials'),
              _buildSettingTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Monthly Budget',
                subtitle: 'Currently ₹${provider.monthlyBudget.toInt()}',
                onTap: () => _showBudgetDialog(context, provider),
              ),
              const SizedBox(height: 16),
              _buildSection('Data Management'),
              _buildSettingTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Clear History',
                subtitle: 'Permanently delete all meal logs',
                color: AppTheme.errorColor,
                onTap: () => _showDeleteConfirm(context, provider),
              ),
              _buildSettingTile(
                icon: Icons.refresh_rounded,
                title: 'Reset App',
                subtitle: 'Remove all custom food items and data',
                color: AppTheme.errorColor,
                onTap: () => _showResetConfirm(context, provider),
              ),
              const SizedBox(height: 16),
              _buildSection('About'),
              const ListTile(
                title: Text('Version'),
                trailing: Text('1.0.0', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1),
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, Color? color}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.black.withOpacity(0.05))),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, FoodProvider provider) {
    final controller = TextEditingController(text: provider.monthlyBudget.toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₹)'),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, FoodProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text('This will delete all your meal logs permanently. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await provider.clearAllSessions();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared!')));
            }, 
            child: const Text('CLEAR ALL', style: TextStyle(color: AppTheme.errorColor))
          ),
        ],
      ),
    );
  }

  void _showResetConfirm(BuildContext context, FoodProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Everything?'),
        content: const Text('This will delete all food items and all history. The app will return to its original state.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await provider.fullReset();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App has been reset!')));
            }, 
            child: const Text('FULL RESET', style: TextStyle(color: AppTheme.errorColor))
          ),
        ],
      ),
    );
  }
}
