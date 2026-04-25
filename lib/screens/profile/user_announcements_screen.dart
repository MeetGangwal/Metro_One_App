import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/admin_provider.dart';

class UserAnnouncementsScreen extends StatelessWidget {
  const UserAnnouncementsScreen({super.key});

  static const _lineNames = {
    'blue': 'Blue Line',
    'yellow': 'Yellow Line',
    'red': 'Red Line',
    'aqua': 'Aqua Line',
  };

  static const _lineColors = {
    'blue': AppColors.blueLine,
    'yellow': AppColors.yellowLine,
    'red': AppColors.redLine,
    'aqua': AppColors.aquaLine,
  };

  IconData _catIcon(String c) => switch (c) {
        'Delay' => Icons.schedule_rounded,
        'Cancellation' => Icons.cancel_rounded,
        _ => Icons.info_rounded,
      };

  Color _catColor(String c) => switch (c) {
        'Delay' => AppColors.warning,
        'Cancellation' => AppColors.error,
        _ => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF12172E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: AppColors.error, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Announcements & Alerts',
                              style: Theme.of(context).textTheme.titleLarge),
                          const Text('Live updates from Mumbai Metro',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              // ── Announcements Stream ──
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      );
                    }

                    if (snap.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 48),
                            const SizedBox(height: 12),
                            Text('Failed to load announcements',
                                style: TextStyle(
                                    color:
                                        AppColors.error.withValues(alpha: 0.8),
                                    fontSize: 14)),
                          ],
                        ),
                      );
                    }

                    final docs = snap.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                color: AppColors.success.withValues(alpha: 0.6),
                                size: 64),
                            const SizedBox(height: 16),
                            const Text('All Clear!',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            const Text(
                                'No active alerts right now.\nAll metro lines are running smoothly.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final msg = data['message'] ?? '';
                        final cat = data['category'] ?? 'General';
                        final lineId = data['line'] ?? '';
                        final ts =
                            (data['createdAt'] as Timestamp?)?.toDate();
                        final lineColor =
                            _lineColors[lineId] ?? AppColors.textMuted;
                        final lineName = _lineNames[lineId] ?? lineId;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    _catColor(cat).withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Line + Category badges row
                              Row(
                                children: [
                                  // Line badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          lineColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: lineColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(lineName,
                                            style: TextStyle(
                                                color: lineColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Category badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _catColor(cat)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_catIcon(cat),
                                            size: 12,
                                            color: _catColor(cat)),
                                        const SizedBox(width: 4),
                                        Text(cat,
                                            style: TextStyle(
                                                color: _catColor(cat),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // Timestamp
                                  if (ts != null)
                                    Text(_formatTime(ts),
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 10)),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Message
                              Text(msg,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4)),

                              // Relative time
                              if (ts != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        color: AppColors.textMuted,
                                        size: 12),
                                    const SizedBox(width: 4),
                                    Text(_timeAgo(ts),
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(
                                delay: Duration(milliseconds: 80 * i),
                                duration: 300.ms)
                            .slideY(begin: 0.05, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }
}
