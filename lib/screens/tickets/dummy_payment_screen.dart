import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DummyPaymentScreen extends StatelessWidget {
  final double amount;

  const DummyPaymentScreen({super.key, required this.amount});

  void _processPayment(BuildContext context, String method) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Processing $method Payment...',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please do not close this screen.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    // Ensure dialog is popped
    if (context.mounted) {
      Navigator.pop(context); // pop dialog
      Navigator.pop(context, true); // pop screen, return true
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text('Secure Payment', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Amount to Pay',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Select Payment Method',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPaymentOption(
              context,
              title: 'UPI',
              subtitle: 'Google Pay, PhonePe, Paytm',
              icon: Icons.qr_code_scanner_rounded,
              color: const Color(0xFF00BFA5),
            ),
            _buildPaymentOption(
              context,
              title: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard, RuPay',
              icon: Icons.credit_card_rounded,
              color: const Color(0xFF2962FF),
            ),
            _buildPaymentOption(
              context,
              title: 'Net Banking',
              subtitle: 'All Indian Banks supported',
              icon: Icons.account_balance_rounded,
              color: const Color(0xFFFF6D00),
            ),
            _buildPaymentOption(
              context,
              title: 'Wallets',
              subtitle: 'Amazon Pay, MobiKwik, etc.',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFFAA00FF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        onTap: () => _processPayment(context, title),
      ),
    );
  }
}
