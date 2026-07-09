import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/wallet_provider.dart';

class DetailedDummyPaymentScreen extends StatefulWidget {
  final double amount;
  final bool isAddingMoney;

  const DetailedDummyPaymentScreen({
    super.key, 
    required this.amount,
    this.isAddingMoney = false,
  });

  @override
  State<DetailedDummyPaymentScreen> createState() => _DetailedDummyPaymentScreenState();
}

class _DetailedDummyPaymentScreenState extends State<DetailedDummyPaymentScreen> {
  String? _selectedMethod;
  bool _saveCard = false;
  bool _saveUpi = false;

  // Controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _upiController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    // Basic validation based on selected method
    if (_selectedMethod == null && _selectedSavedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedSavedMethod == null && _selectedMethod == 'card') {
      if (!_formKey.currentState!.validate()) return;
    }
    if (_selectedSavedMethod == null && _selectedMethod == 'upi') {
       if (_upiController.text.isEmpty || !_upiController.text.contains('@')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid UPI ID'), backgroundColor: AppColors.error),
          );
          return;
       }
    }

    if (_selectedMethod == 'wallet') {
      final wallet = context.read<WalletProvider>();
      final success = await wallet.deductMoney(widget.amount, 'Ticket Purchase');
      if (!success) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to deduct from wallet'), backgroundColor: AppColors.error),
         );
         return;
      }
      if (context.mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

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
              const Text(
                'Processing Payment... Please wait.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Securing connection to bank gateway.',
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

  String? _selectedSavedMethod;

  void _showAddMoneyDialog(WalletProvider wallet) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Add Money to Wallet', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter amount',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(amountController.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx);
                final success = await wallet.addMoney(val);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('₹$val added to wallet successfully'), backgroundColor: AppColors.success),
                  );
                }
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: AppColors.error),
                  );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add Money', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text('Secure Checkout', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                            '₹${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (!widget.isAddingMoney) ...[
                      _buildWalletSection(walletProvider),
                      const SizedBox(height: 24),
                    ],
                    
                    const Text('Saved Options', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _buildSavedMethod(
                       title: 'HDFC Bank Credit Card',
                       subtitle: 'Visa ending in **** 1234',
                       icon: Icons.credit_card,
                       value: 'saved_card',
                    ),
                    _buildSavedMethod(
                       title: 'Google Pay',
                       subtitle: 'username@okaxis',
                       icon: Icons.qr_code_scanner,
                       value: 'saved_upi',
                    ),
                    
                    const SizedBox(height: 24),
                    const Text('Other Payment Methods', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    
                    _buildCardExpansion(),
                    const SizedBox(height: 12),
                    _buildUpiExpansion(),
                    const SizedBox(height: 12),
                    _buildNetBankingExpansion(),
                  ],
                ),
              ),
            ),
          ),
          
          // Pay Button Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
               color: AppColors.surface,
               boxShadow: [
                 BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))
               ]
            ),
            child: SizedBox(
               width: double.infinity,
               height: 56,
               child: ElevatedButton(
                 onPressed: _processPayment,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 ),
                 child: Text(
                   'Pay ₹${widget.amount.toStringAsFixed(2)}',
                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                 ),
               ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSavedMethod({required String title, required String subtitle, required IconData icon, required String value}) {
     bool isSelected = _selectedSavedMethod == value;
     return GestureDetector(
       onTap: () {
         setState(() {
            _selectedSavedMethod = value;
            _selectedMethod = null; // Unselect new methods
         });
       },
       child: Container(
         margin: const EdgeInsets.only(bottom: 12),
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: AppColors.surfaceLight,
           border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
           borderRadius: BorderRadius.circular(12),
         ),
         child: Row(
           children: [
             Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                 ],
               )
             ),
             if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary)
           ],
         ),
       ),
     );
  }

  Widget _buildCardExpansion() {
    return Container(
      decoration: BoxDecoration(
         color: AppColors.surfaceCard,
         borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('Credit / Debit Card', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          leading: const Icon(Icons.credit_card_rounded, color: Color(0xFF2962FF)),
          onExpansionChanged: (expanded) {
             if (expanded) setState(() { _selectedMethod = 'card'; _selectedSavedMethod = null; });
          },
          childrenPadding: const EdgeInsets.all(16),
          children: [
             TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                inputFormatters: [
                   FilteringTextInputFormatter.digitsOnly,
                   LengthLimitingTextInputFormatter(16),
                ],
                decoration: _inputDecoration('Card Number (16 digits)'),
                validator: (val) => (val == null || val.length != 16) ? 'Enter valid 16 digit card number' : null,
             ),
             const SizedBox(height: 16),
             Row(
               children: [
                 Expanded(
                   child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.datetime,
                      style: const TextStyle(color: AppColors.textPrimary),
                      inputFormatters: [LengthLimitingTextInputFormatter(5)],
                      decoration: _inputDecoration('MM/YY'),
                      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                      decoration: _inputDecoration('CVV'),
                      validator: (val) => (val == null || val.length != 3) ? 'Required' : null,
                   ),
                 )
               ],
             ),
             const SizedBox(height: 12),
             CheckboxListTile(
               value: _saveCard,
               onChanged: (val) => setState(() => _saveCard = val ?? false),
               title: const Text('Save this card for future payments', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
               controlAffinity: ListTileControlAffinity.leading,
               contentPadding: EdgeInsets.zero,
               activeColor: AppColors.primary,
             )
          ],
        ),
      ),
    );
  }

  Widget _buildUpiExpansion() {
    return Container(
      decoration: BoxDecoration(
         color: AppColors.surfaceCard,
         borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('UPI', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          leading: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF00BFA5)),
          onExpansionChanged: (expanded) {
             if (expanded) setState(() { _selectedMethod = 'upi'; _selectedSavedMethod = null; });
          },
          childrenPadding: const EdgeInsets.all(16),
          children: [
             TextFormField(
                controller: _upiController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('UPI ID (e.g., username@bank)'),
             ),
             const SizedBox(height: 12),
             CheckboxListTile(
               value: _saveUpi,
               onChanged: (val) => setState(() => _saveUpi = val ?? false),
               title: const Text('Save this UPI ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
               controlAffinity: ListTileControlAffinity.leading,
               contentPadding: EdgeInsets.zero,
               activeColor: AppColors.primary,
             )
          ],
        ),
      ),
    );
  }

  Widget _buildNetBankingExpansion() {
    return Container(
      decoration: BoxDecoration(
         color: AppColors.surfaceCard,
         borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('Net Banking & Wallets', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          leading: const Icon(Icons.account_balance_rounded, color: Color(0xFFFF6D00)),
          onExpansionChanged: (expanded) {
             if (expanded) setState(() { _selectedMethod = 'netbanking'; _selectedSavedMethod = null; });
          },
          childrenPadding: const EdgeInsets.all(16),
          children: [
             Wrap(
               spacing: 12,
               runSpacing: 12,
               children: [
                  _bankChip('SBI'),
                  _bankChip('HDFC'),
                  _bankChip('ICICI'),
                  _bankChip('Axis Bank'),
                  _bankChip('Paytm'),
                  _bankChip('Amazon Pay'),
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _bankChip(String name) {
     return Chip(
        label: Text(name, style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surfaceLight,
        side: const BorderSide(color: Colors.transparent),
     );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildWalletSection(WalletProvider wallet) {
    final bool canAfford = wallet.balance >= widget.amount;
    final bool isSelected = _selectedMethod == 'wallet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Wallet', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Balance', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      Text(
                        '₹${wallet.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: canAfford ? AppColors.textPrimary : AppColors.error,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: wallet.isLoading ? null : () => _showAddMoneyDialog(wallet),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: wallet.isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Text('Add Money', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceLight, height: 1),
              const SizedBox(height: 16),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (canAfford) {
                    setState(() {
                      _selectedMethod = 'wallet';
                      _selectedSavedMethod = null;
                    });
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: canAfford ? (isSelected ? AppColors.primary : AppColors.textPrimary) : AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pay with Wallet', style: TextStyle(color: canAfford ? AppColors.textPrimary : AppColors.textMuted, fontWeight: FontWeight.w600)),
                          if (!canAfford)
                            const Text('Insufficient Wallet Balance', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
