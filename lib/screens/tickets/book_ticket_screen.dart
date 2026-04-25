import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/ticket_provider.dart';
import '../main_nav/main_navigation.dart';
import 'dummy_payment_screen.dart';

class BookTicketScreen extends StatefulWidget {
  final MetroRoute route;

  const BookTicketScreen({super.key, required this.route});

  @override
  State<BookTicketScreen> createState() => _BookTicketScreenState();
}

class _BookTicketScreenState extends State<BookTicketScreen> {
  int _quantity = 1;
  bool _isBooking = false;
  String _ticketType = 'regular'; // 'regular', 'monthly_pass'
  String _journeyType = 'single'; // 'single', 'return'

  @override
  Widget build(BuildContext context) {
    double baseFare = widget.route.fare;
    if (_ticketType == 'monthly_pass') {
      baseFare = baseFare * 30;
    } else if (_journeyType == 'return') {
      baseFare = baseFare * 2;
    }
    final totalFare = baseFare * _quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Book Ticket',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Ticket Tabs
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildTabBtn('Regular', 'regular')),
                          Expanded(child: _buildTabBtn('Monthly Pass', 'monthly_pass')),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    // Journey Type Tabs (Only for Regular)
                    if (_ticketType == 'regular')
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildJourneyBtn('Single Journey', 'single')),
                            Expanded(child: _buildJourneyBtn('Return Journey', 'return')),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),

                    // Journey summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.ticketGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('FROM',
                                        style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(widget.route.source.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.train_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('TO',
                                        style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(widget.route.destination.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.end),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _summaryItem('Stops', '${widget.route.totalStops}'),
                              _summaryItem('Time', '${widget.route.estimatedMinutes} min'),
                              _summaryItem('Changes', '${widget.route.interchanges}'),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // Route details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Route',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ...widget.route.segments.map((seg) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: seg.lineColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${seg.lineName}: ${seg.stations.first.name} → ${seg.stations.last.name}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${seg.stops} stops',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 24),

                    // Quantity selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text('Quantity',
                              style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.remove,
                                  color: AppColors.textPrimary, size: 18),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_quantity < 10) {
                                setState(() => _quantity++);
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 24),

                    // Fare breakdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          if (_ticketType == 'monthly_pass')
                            _fareRow('Pass Price', '₹${baseFare.toStringAsFixed(0)}')
                          else if (_journeyType == 'return')
                            _fareRow('Return Fare', '₹${baseFare.toStringAsFixed(0)}')
                          else
                            _fareRow('Base Fare', '₹${baseFare.toStringAsFixed(0)}'),
                          if (_quantity > 1)
                            _fareRow('Quantity', '×$_quantity'),
                          Divider(color: AppColors.textMuted.withValues(alpha: 0.1)),
                          Row(
                            children: [
                              Text('Total',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(
                                '₹${totalFare.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 32),

                    // Book button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isBooking ? null : () => _bookTicket(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isBooking
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Pay ₹${totalFare.toStringAsFixed(0)} & Book',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, String value) {
    bool isSelected = _ticketType == value;
    return GestureDetector(
      onTap: () {
         setState(() {
            _ticketType = value;
            if (value == 'monthly_pass') _journeyType = 'single';
         });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
           color: isSelected ? Colors.white : AppColors.textPrimary,
           fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
           fontSize: 13,
        )),
      ),
    );
  }

  Widget _buildJourneyBtn(String label, String value) {
    bool isSelected = _journeyType == value;
    return GestureDetector(
      onTap: () => setState(() => _journeyType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
           color: isSelected ? AppColors.primary : AppColors.textPrimary,
           fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
           fontSize: 13,
        )),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _fareRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _bookTicket(BuildContext context) async {
    double baseFare = widget.route.fare;
    if (_ticketType == 'monthly_pass') {
      baseFare = baseFare * 30;
    } else if (_journeyType == 'return') {
      baseFare = baseFare * 2;
    }
    final totalFare = baseFare * _quantity;

    // Launch Dummy Payment Gateway
    final bool? paymentSuccess = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DummyPaymentScreen(amount: totalFare),
      ),
    );

    // If user cancelled or payment failed, abort booking
    if (paymentSuccess != true) {
      return;
    }

    if (!context.mounted) return;

    setState(() => _isBooking = true);

    final ticketProvider = context.read<TicketProvider>();
    final routeSummary = widget.route.segments
        .map((s) => '${s.lineName}: ${s.stations.first.name} → ${s.stations.last.name}')
        .join(' | ');
    final reverseRouteSummary = widget.route.segments.reversed
        .map((s) => '${s.lineName}: ${s.stations.last.name} → ${s.stations.first.name}')
        .join(' | ');
        
    final linesTaken = widget.route.linesTaken;

    for (int i = 0; i < _quantity; i++) {
        if (_ticketType == 'monthly_pass') {
           await ticketProvider.bookTicket(
             source: widget.route.source.name,
             destination: widget.route.destination.name,
             stops: widget.route.totalStops,
             fare: baseFare,
             estimatedMinutes: widget.route.estimatedMinutes,
             routeSummary: routeSummary,
             linesTaken: linesTaken,
             ticketType: 'monthly_pass',
           );
        } else if (_journeyType == 'return') {
           // Book forward
           await ticketProvider.bookTicket(
             source: widget.route.source.name,
             destination: widget.route.destination.name,
             stops: widget.route.totalStops,
             fare: baseFare / 2,
             estimatedMinutes: widget.route.estimatedMinutes,
             routeSummary: routeSummary,
             linesTaken: linesTaken,
             ticketType: 'return',
           );
           // Book backward
           await ticketProvider.bookTicket(
             source: widget.route.destination.name,
             destination: widget.route.source.name,
             stops: widget.route.totalStops,
             fare: baseFare / 2,
             estimatedMinutes: widget.route.estimatedMinutes,
             routeSummary: reverseRouteSummary,
             linesTaken: linesTaken,
             ticketType: 'return',
           );
        } else {
           await ticketProvider.bookTicket(
             source: widget.route.source.name,
             destination: widget.route.destination.name,
             stops: widget.route.totalStops,
             fare: baseFare,
             estimatedMinutes: widget.route.estimatedMinutes,
             routeSummary: routeSummary,
             linesTaken: linesTaken,
             ticketType: 'single',
           );
        }
    }

    if (mounted) {
      setState(() => _isBooking = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 20),
              Text('Booking Confirmed!',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '$_quantity ticket${_quantity > 1 ? 's' : ''} booked successfully',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    MainNavigation.navKey.currentState?.switchToTab(4);
                  },
                  child: const Text('View Tickets'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
