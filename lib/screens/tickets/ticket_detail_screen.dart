import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/ticket_provider.dart';
import '../../core/services/notification_service.dart';

class TicketDetailScreen extends StatelessWidget {
  final MetroTicket ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isActive = ticket.status == 'active';

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
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ticket Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.textMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'USED',
                      style: TextStyle(
                        color: isActive
                            ? AppColors.success
                            : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Ticket card
                    Container(
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? AppColors.ticketGradient
                            : const LinearGradient(
                                colors: [
                                  AppColors.surfaceCard,
                                  AppColors.surfaceLight,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Header
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.train_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Mumbai Metro',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '₹${ticket.fare.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ticket.source,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'FROM',
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 10,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white54,
                                          size: 20,
                                        ),
                                        Text(
                                          '${ticket.stops} stops',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            ticket.destination,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            textAlign: TextAlign.end,
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'TO',
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 10,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _infoCol(
                                      'Date',
                                      DateFormat(
                                        'dd MMM yyyy',
                                      ).format(ticket.createdAt),
                                    ),
                                    _infoCol(
                                      'Time',
                                      DateFormat(
                                        'hh:mm a',
                                      ).format(ticket.createdAt),
                                    ),
                                    _infoCol(
                                      'Duration',
                                      '${ticket.estimatedMinutes} min',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Divider with notches
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: List.generate(
                                    40,
                                    (i) => Expanded(
                                      child: Container(
                                        height: 1,
                                        color: i.isEven
                                            ? Colors.white24
                                            : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),

                          // QR Code
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: QrImageView(
                                      data: jsonEncode({
                                        'ticketId': ticket.id,
                                        'source': ticket.source,
                                        'destination': ticket.destination,
                                        'price': ticket.fare,
                                        'linesTaken': ticket.linesTaken,
                                        'timestamp': ticket.createdAt.toIso8601String(),
                                      }),
                                      version: QrVersions.auto,
                                      size: 180,
                                      backgroundColor: Colors.white,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: Color(0xFF0A0E21),
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.square,
                                        color: Color(0xFF0A0E21),
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 300.ms)
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1.0, 1.0),
                                  )
                                else
                                  Container(
                                    width: 180,
                                    height: 180,
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.qr_code_scanner_rounded, color: Colors.white38, size: 64),
                                        SizedBox(height: 16),
                                        Text('Expired', style: TextStyle(color: Colors.white54, fontSize: 14)),
                                      ],
                                    ),
                                  ).animate().fadeIn(delay: 300.ms),
                                const SizedBox(height: 12),
                                Text(
                                  'Scan at gate to enter/exit',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white60
                                        : AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ticket ID: ${ticket.id.substring(0, 8).toUpperCase()}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white38
                                        : AppColors.textMuted,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 20),

                    // Route summary
                    if (ticket.routeSummary.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route Summary',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ticket.routeSummary.replaceAll(' | ', '\n→ '),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 20),

                    if (isActive && ticket.ticketType != 'monthly_pass')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _markAsUsed(context),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: const Text('Mark as Used'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: BorderSide(
                              color: AppColors.success.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms),

                    if (isActive) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                              await NotificationService().scheduleDestinationAlarm(
                                  ticket.estimatedMinutes,
                                  ticket.destination,
                              );
                              if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Alarm set! We will wake you up before you reach ${ticket.destination}.'),
                                          backgroundColor: AppColors.primary,
                                      ),
                                  );
                              }
                          },
                          icon: const Icon(
                            Icons.alarm_add_rounded,
                            size: 18,
                          ),
                          label: const Text('Set Destination Alarm (Wake Me)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 450.ms),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _markAsUsed(BuildContext context) {
    context.read<TicketProvider>().useTicket(ticket.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ticket marked as used')));
  }


}
