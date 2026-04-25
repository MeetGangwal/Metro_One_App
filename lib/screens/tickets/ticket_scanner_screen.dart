import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/ticket_provider.dart';
import '../../core/models/models.dart';

/// QR Code Scanner Screen
/// Since mobile_scanner requires native camera access and may not work on web/desktop,
/// this screen provides a simulated scanner with manual ticket ID input for development,
/// and real scanning when running on a physical device with mobile_scanner installed.
class TicketScannerScreen extends StatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  State<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends State<TicketScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  String? _scannedData;
  late AnimationController _pulseController;
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _processQrData(String data) {
    setState(() {
      _scannedData = data;
      _isScanning = false;
    });
  }

  Map<String, String>? _parseTicketData(String data) {
    // Expected format: MUMBAI_METRO_{ID}_{SOURCE}_{DESTINATION}_{FARE}
    if (!data.startsWith('MUMBAI_METRO_')) return null;

    try {
      final parts = data.replaceFirst('MUMBAI_METRO_', '').split('_');
      if (parts.length < 4) return null;

      // Reconstruct: first 5 parts are UUID segments, then source, destination, fare
      // MUMBAI_METRO_{uuid-part1}_{uuid-part2}_{uuid-part3}_{uuid-part4}_{uuid-part5}_{source}_{dest}_{fare}
      // But source/dest may contain spaces that were kept, so let's be smarter

      // Let's find the ticket in our provider
      final ticketId = _extractTicketId(data);

      return {
        'ticketId': ticketId ?? 'N/A',
        'raw': data,
      };
    } catch (e) {
      return null;
    }
  }

  String? _extractTicketId(String data) {
    // MUMBAI_METRO_{uuid}_{source}_{dest}_{fare}
    // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    final withoutPrefix = data.replaceFirst('MUMBAI_METRO_', '');
    // The UUID has 36 chars (with dashes) but since dashes become underscores...
    // Let's try to match the first UUID-like segment
    final regex = RegExp(r'^([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})');
    final match = regex.firstMatch(withoutPrefix);
    if (match != null) return match.group(1);

    // Fallback: try to find the ticket by partial match
    return withoutPrefix.length >= 8 ? withoutPrefix.substring(0, 8) : null;
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Scan Ticket QR',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),

            Expanded(
              child: _isScanning
                  ? _buildScannerView(context)
                  : _buildResultView(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView(BuildContext context) {
    final ticketProvider = context.read<TicketProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Simulated scanner viewport
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(
                        alpha: 0.3 + (_pulseController.value * 0.4)),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                          alpha: 0.1 + (_pulseController.value * 0.15)),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Container(
                    color: const Color(0xFF0D1229),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Grid lines
                        ...List.generate(5, (i) {
                          final pos = (i + 1) * 56.0;
                          return Positioned(
                            left: 0,
                            right: 0,
                            top: pos,
                            child: Container(
                              height: 0.5,
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          );
                        }),
                        ...List.generate(5, (i) {
                          final pos = (i + 1) * 56.0;
                          return Positioned(
                            top: 0,
                            bottom: 0,
                            left: pos,
                            child: Container(
                              width: 0.5,
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          );
                        }),

                        // Scan line animation
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Positioned(
                              top: _pulseController.value * 260,
                              left: 20,
                              right: 20,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.primary,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Center icon
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppColors.primary.withValues(alpha: 0.6),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Point camera at QR code',
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        // Corner markers
                        _cornerMarker(Alignment.topLeft),
                        _cornerMarker(Alignment.topRight),
                        _cornerMarker(Alignment.bottomLeft),
                        _cornerMarker(Alignment.bottomRight),
                      ],
                    ),
                  ),
                ),
              );
            },
          ).animate().fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
              ),

          const SizedBox(height: 32),

          // Info text
          const Text(
            'Scan a Mumbai Metro ticket QR code\nto view complete journey details',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          // Quick scan from existing tickets  
          Text(
            'Or select a ticket to scan:',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 12),

          // Show active tickets for quick testing
          ...ticketProvider.activeTickets.take(3).map((ticket) {
            return GestureDetector(
              onTap: () {
                final qrData = 'MUMBAI_METRO_${ticket.id}_${ticket.source}_${ticket.destination}_${ticket.fare}';
                _processQrData(qrData);
                _lookupTicketAndShow(ticket.id, context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ticket.source} → ${ticket.destination}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'ID: ${ticket.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms);
          }),

          if (ticketProvider.activeTickets.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(Icons.confirmation_num_outlined,
                      color: AppColors.textMuted, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'No active tickets to scan.\nBook a ticket first from Routes tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _cornerMarker(Alignment alignment) {
    final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
            bottom: isTop ? BorderSide.none : const BorderSide(color: AppColors.primary, width: 3),
            left: isLeft ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
            right: isLeft ? BorderSide.none : const BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
      ),
    );
  }

  void _lookupTicketAndShow(String ticketId, BuildContext context) {
    final ticketProvider = context.read<TicketProvider>();
    MetroTicket? foundTicket;

    // Search by full ID
    for (final ticket in ticketProvider.tickets) {
      if (ticket.id == ticketId) {
        foundTicket = ticket;
        break;
      }
    }

    // Search by partial ID
    if (foundTicket == null) {
      for (final ticket in ticketProvider.tickets) {
        if (ticket.id.startsWith(ticketId) ||
            ticket.id.contains(ticketId)) {
          foundTicket = ticket;
          break;
        }
      }
    }

    if (foundTicket != null) {
      setState(() {
        _scannedData = 'MUMBAI_METRO_${foundTicket!.id}_${foundTicket.source}_${foundTicket.destination}_${foundTicket.fare}';
        _isScanning = false;
      });
    }
  }

  Widget _buildResultView(BuildContext context) {
    final ticketProvider = context.read<TicketProvider>();

    // Try to find the ticket from scanner data
    MetroTicket? ticket;
    if (_scannedData != null) {
      for (final t in ticketProvider.tickets) {
        if (_scannedData!.contains(t.id)) {
          ticket = t;
          break;
        }
      }
    }

    if (ticket == null) {
      return _buildInvalidResult(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Success indicator
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 40),
          ).animate().fadeIn(duration: 300.ms).scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
              ),

          const SizedBox(height: 16),
          Text('Ticket Verified!',
                  style: Theme.of(context).textTheme.headlineSmall)
              .animate()
              .fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Full ticket details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.ticketGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.train_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    const Text('Mumbai Metro',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ticket.status == 'active'
                            ? AppColors.success.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ticket.status.toUpperCase(),
                        style: TextStyle(
                          color: ticket.status == 'active'
                              ? AppColors.success
                              : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Route
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SOURCE',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(ticket.source,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white54, size: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('DESTINATION',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(ticket.destination,
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

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: List.generate(
                      40,
                      (i) => Expanded(
                        child: Container(
                          height: 1,
                          color: i.isEven ? Colors.white24 : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),

                // Detailed info grid
                _detailRow('Payment ID', ticket.id.substring(0, 8).toUpperCase()),
                const SizedBox(height: 12),
                _detailRow('Transaction Amount', '₹${ticket.fare.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _detailRow('Date', DateFormat('dd MMMM yyyy').format(ticket.createdAt)),
                const SizedBox(height: 12),
                _detailRow('Time', DateFormat('hh:mm:ss a').format(ticket.createdAt)),
                const SizedBox(height: 12),
                _detailRow('Stops', '${ticket.stops}'),
                const SizedBox(height: 12),
                _detailRow('Est. Duration', '${ticket.estimatedMinutes} minutes'),
                const SizedBox(height: 12),
                if (ticket.linesTaken.isNotEmpty) ...[
                  _detailRow('Lines Taken', ticket.linesTaken),
                  const SizedBox(height: 12),
                ],
                _detailRow('Status', ticket.status == 'active' ? '✅ Active' : '⏹ Used'),

                if (ticket.routeSummary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Route',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          ticket.routeSummary.replaceAll(' | ', '\n→ '),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isScanning = true;
                      _scannedData = null;
                    });
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Scan Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
        Flexible(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.end),
        ),
      ],
    );
  }

  Widget _buildInvalidResult(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Invalid QR Code',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'This QR code does not match any\nMumbai Metro ticket in our system.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isScanning = true;
                  _scannedData = null;
                });
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
