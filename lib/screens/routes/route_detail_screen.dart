import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/crowd_provider.dart';
import '../../core/providers/favorites_provider.dart';
import '../tickets/book_ticket_screen.dart';

class RouteDetailScreen extends StatelessWidget {
  final MetroRoute route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final crowd = context.watch<CrowdProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Save Route button
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
                  Expanded(
                    child: Text(
                      'Route Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  // Save Route toggle button
                  Consumer<FavoritesProvider>(
                    builder: (_, fav, __) {
                      final isFav = fav.isFavorite(
                        route.source.name,
                        route.destination.name,
                      );
                      return GestureDetector(
                        onTap: () {
                          fav.toggleFavorite(
                            route.source.name,
                            route.destination.name,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFav
                                    ? 'Route removed from favorites'
                                    : 'Route saved to favorites ⭐',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isFav
                                ? AppColors.yellowLine.withValues(alpha: 0.15)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFav
                                  ? AppColors.yellowLine.withValues(alpha: 0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isFav
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: isFav
                                    ? AppColors.yellowLine
                                    : AppColors.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isFav ? 'Saved' : 'Save',
                                style: TextStyle(
                                  color: isFav
                                      ? AppColors.yellowLine
                                      : AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card
                    _buildSummaryCard(context)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 20),

                    // Route timeline
                    Text(
                      'Journey Timeline',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 16),

                    ...List.generate(route.segments.length, (segIndex) {
                      final segment = route.segments[segIndex];
                      return Column(
                        children: [
                          // Line header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: segment.lineColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: segment.lineColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  segment.lineName,
                                  style: TextStyle(
                                    color: segment.lineColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${segment.stops} stops',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: (300 + segIndex * 100).ms),

                          const SizedBox(height: 8),

                          // Station list
                          ...segment.stations.asMap().entries.map((entry) {
                            final i = entry.key;
                            final station = entry.value;
                            final isFirst = i == 0 && segIndex == 0;
                            final isLast = i == segment.stations.length - 1 &&
                                segIndex == route.segments.length - 1;
                            final isInterchange =
                                i == segment.stations.length - 1 &&
                                    segIndex < route.segments.length - 1;
                            final crowdLevel = crowd.getCrowdLevel(station.id);
                            final dynFacilities = crowd.getFacilities(station.id);
                            final outOfService = dynFacilities.entries.where((e) => !e.value).map((e) => e.key).toList();

                            return Container(
                              margin: const EdgeInsets.only(left: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Timeline
                                  Column(
                                    children: [
                                      Container(
                                        width: isFirst || isLast || isInterchange
                                            ? 14
                                            : 10,
                                        height: isFirst || isLast || isInterchange
                                            ? 14
                                            : 10,
                                        decoration: BoxDecoration(
                                          color: isFirst || isLast
                                              ? segment.lineColor
                                              : isInterchange
                                                  ? AppColors.warning
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color: segment.lineColor,
                                            width: 2,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      if (!(isLast))
                                        Container(
                                          width: 2,
                                          height: 32,
                                          color: segment.lineColor
                                              .withValues(alpha: 0.4),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Station info
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  station.name,
                                                  style: TextStyle(
                                                    color: isFirst || isLast
                                                        ? AppColors.textPrimary
                                                        : AppColors
                                                            .textSecondary,
                                                    fontSize:
                                                        isFirst || isLast
                                                            ? 14
                                                            : 13,
                                                    fontWeight:
                                                        isFirst || isLast
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                  ),
                                                ),
                                                if (isInterchange)
                                                  Text(
                                                    '🔄 Change to ${route.segments[segIndex + 1].lineName}',
                                                    style: const TextStyle(
                                                      color: AppColors.warning,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                if (station.platformSide != null || (station.gates != null && station.gates!.isNotEmpty) || outOfService.isNotEmpty)
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 8),
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      color: segment.lineColor.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: segment.lineColor.withValues(alpha: 0.3)),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        if (station.platformSide != null)
                                                          Padding(
                                                            padding: const EdgeInsets.only(bottom: 4),
                                                            child: Text(
                                                              '🚪 Doors open on the ${station.platformSide}',
                                                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                                                            ),
                                                          ),
                                                        if (station.gates != null && station.gates!.isNotEmpty)
                                                          ...station.gates!.map((gate) => Padding(
                                                            padding: const EdgeInsets.only(top: 2),
                                                            child: Text('🧭 $gate', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                                          )),
                                                        if (outOfService.isNotEmpty)
                                                          Padding(
                                                            padding: const EdgeInsets.only(top: 6),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: outOfService.map((f) => Row(
                                                                children: [
                                                                  const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.error),
                                                                  const SizedBox(width: 4),
                                                                  Text('${f.toUpperCase()} is Out of Service', style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
                                                                ],
                                                              )).toList(),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Crowd indicator
                                          if (crowdLevel != CrowdLevel.unknown)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: crowd
                                                    .getCrowdColor(station.id)
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Icon(
                                                crowd.getCrowdIcon(station.id),
                                                color: crowd
                                                    .getCrowdColor(station.id),
                                                size: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          if (segIndex < route.segments.length - 1)
                            const SizedBox(height: 8),
                        ],
                      );
                    }),

                    const SizedBox(height: 24),

                    // Book Ticket Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookTicketScreen(route: route),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.confirmation_num_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Book Ticket - ₹${route.fare.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Source → Destination
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FROM',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route.source.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.primary, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TO',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route.destination.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.1)),
          const SizedBox(height: 16),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Stops', '${route.totalStops}', Icons.train_rounded),
              _statItem('Time', '${route.estimatedMinutes} min',
                  Icons.access_time_rounded),
              _statItem(
                  'Fare', '₹${route.fare.toStringAsFixed(0)}', Icons.currency_rupee),
              _statItem('Changes', '${route.interchanges}',
                  Icons.swap_horiz_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
