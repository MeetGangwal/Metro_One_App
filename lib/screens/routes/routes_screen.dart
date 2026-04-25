import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/metro_provider.dart';

import '../../core/providers/favorites_provider.dart';
import 'station_search_screen.dart';
import 'route_detail_screen.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metro = context.watch<MetroProvider>();

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
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Planner',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Find the best route for your journey',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ).animate().fadeIn(delay: 100.ms),
                  ],
                ),
              ),

              // Route Planner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildRoutePlanner(context, metro),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              // Results
              Expanded(
                child: metro.routes.isEmpty
                    ? _buildEmptyState(context, metro)
                    : _buildRouteResults(context, metro),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutePlanner(BuildContext context, MetroProvider metro) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Source
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StationSearchScreen(isSource: true),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: metro.sourceStation != null
                      ? AppColors.success.withValues(alpha: 0.5)
                      : AppColors.textMuted.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      metro.sourceStation?.name ?? 'Select Source Station',
                      style: TextStyle(
                        color: metro.sourceStation != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: metro.sourceStation != null
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
          ),

          // Swap + Connector
          Row(
            children: [
              const SizedBox(width: 21),
              Column(
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 2,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => metro.swapStations(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.swap_vert_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),

          // Destination
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StationSearchScreen(isSource: false),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: metro.destinationStation != null
                      ? AppColors.error.withValues(alpha: 0.5)
                      : AppColors.textMuted.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      metro.destinationStation?.name ??
                          'Select Destination Station',
                      style: TextStyle(
                        color: metro.destinationStation != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: metro.destinationStation != null
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Find Route button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: metro.sourceStation != null &&
                      metro.destinationStation != null
                  ? () {
                      metro.findRoutes();
                      context.read<FavoritesProvider>().addRecentSearch(
                          '${metro.sourceStation!.name} → ${metro.destinationStation!.name}');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Find Routes',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, MetroProvider metro) {
    final favorites = context.watch<FavoritesProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Favorites
          if (favorites.favorites.isNotEmpty) ...[
            Text(
              '⭐ Favorite Routes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ...favorites.favorites.map((fav) => GestureDetector(
                  onTap: () {
                    final sources =
                        metro.metroData.findStationsByName(fav.source);
                    final dests =
                        metro.metroData.findStationsByName(fav.destination);
                    if (sources.isNotEmpty && dests.isNotEmpty) {
                      metro.setSource(sources.first);
                      metro.setDestination(dests.first);
                      metro.findRoutes();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.yellowLine, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${fav.source} → ${fav.destination}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 24),
          ],

          // Recent searches
          if (favorites.recentSearches.isNotEmpty) ...[
            Text(
              '🕐 Recent Searches',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ...favorites.recentSearches.take(10).map((search) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history,
                          color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        search,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          if (favorites.favorites.isEmpty && favorites.recentSearches.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.route_rounded,
                      size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'Select stations above to\nfind the best route',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteResults(BuildContext context, MetroProvider metro) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: metro.routes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  '${metro.routes.length} route${metro.routes.length > 1 ? 's' : ''} found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                // Favorite button
                Consumer<FavoritesProvider>(
                  builder: (_, fav, __) {
                    final isFav = fav.isFavorite(
                      metro.sourceStation!.name,
                      metro.destinationStation!.name,
                    );
                    return GestureDetector(
                      onTap: () => fav.toggleFavorite(
                        metro.sourceStation!.name,
                        metro.destinationStation!.name,
                      ),
                      child: Icon(
                        isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isFav ? AppColors.yellowLine : AppColors.textMuted,
                        size: 24,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        final route = metro.routes[index - 1];
        final isSelected = metro.selectedRoute == route;

        return GestureDetector(
          onTap: () {
            metro.selectRoute(route);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RouteDetailScreen(route: route),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route header
                Row(
                  children: [
                    if (index == 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '⚡ Fastest',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      '₹${route.fare.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Line segments
                Row(
                  children: route.segments.map((seg) {
                    return Expanded(
                      flex: seg.stops,
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: seg.lineColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Route info
                Row(
                  children: [
                    _infoChip(Icons.train_rounded,
                        '${route.totalStops} stops'),
                    const SizedBox(width: 12),
                    _infoChip(Icons.access_time_rounded,
                        '${route.estimatedMinutes} min'),
                    if (route.interchanges > 0) ...[
                      const SizedBox(width: 12),
                      _infoChip(Icons.swap_horiz_rounded,
                          '${route.interchanges} change'),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Line names
                Text(
                  route.segments.map((s) => s.lineName).join(' → '),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.05, end: 0),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
