import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/metro_provider.dart';
import '../../core/providers/crowd_provider.dart';
import '../../core/providers/ticket_provider.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/data/metro_data.dart';
import '../routes/station_search_screen.dart';
import '../routes/metro_schedule_screen.dart';
import '../tickets/ticket_scanner_screen.dart';
import '../main_nav/main_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final crowd = context.watch<CrowdProvider>();
    final metro = context.watch<MetroProvider>();
    final tickets = context.watch<TicketProvider>();
    final insights = crowd.getInsights();

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(context, auth)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 20),

                  // ─── LIVE ANNOUNCEMENTS (from Admin) ───
                  _buildLiveAnnouncements(context)
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  // ─── ADMIN PEAK HOUR BADGES ───
                  _buildAdminPeakHours(context, metro)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // Quick Route Planner Card - NOW STATE AWARE
                  _buildQuickRoutePlanner(context, metro)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Smart Insights
                  _buildInsightsCard(context, insights)
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Quick Stats
                  _buildQuickStats(context, tickets, metro)
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Live ETA Section
                  _buildLiveETA(context, metro)
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Popular Stations
                  _buildPopularStations(context, metro, crowd)
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Crowd Alerts
                  _buildCrowdAlerts(context, crowd)
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      // QR Scanner FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TicketScannerScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppAuthProvider auth) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetIcon;
    if (hour < 12) {
      greeting = 'Good Morning';
      greetIcon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      greetIcon = Icons.nightlight_round;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(greetIcon, color: AppColors.yellowLine, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      greeting,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                auth.userName.isEmpty ? 'Traveller' : auth.userName,
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        // SOS Button
        GestureDetector(
          onTap: () => _showSOSBottomSheet(context, auth),
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.sos_rounded,
                color: AppColors.error, size: 24),
          ),
        ),
        // Scan QR button in header
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TicketScannerScreen()),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                color: AppColors.textSecondary, size: 22),
          ),
        ),
        GestureDetector(
          onTap: () {
            MainNavigation.navKey.currentState?.switchToTab(5);
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                (auth.userName.isEmpty ? 'T' : auth.userName[0]).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// FIX: Now dynamically observes MetroProvider to display selected stations
  /// and navigates to Routes tab on "Find Routes"
  Widget _buildQuickRoutePlanner(BuildContext context, MetroProvider metro) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2440), Color(0xFF252B48)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.route_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'home.whereTo'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Source field — dynamically reads metro.sourceStation
          GestureDetector(
            onTap: () => _openStationSearch(context, true),
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
                      metro.sourceStation?.name ?? 'From Station',
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

          // Swap + Dots connector
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
              if (metro.sourceStation != null || metro.destinationStation != null)
                GestureDetector(
                  onTap: () => metro.swapStations(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swap_vert_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                ),
            ],
          ),

          // Destination field — dynamically reads metro.destinationStation
          GestureDetector(
            onTap: () => _openStationSearch(context, false),
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
                      metro.destinationStation?.name ?? 'To Station',
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

          // Find Route button — navigates to Routes tab
          if (metro.sourceStation != null && metro.destinationStation != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Find routes and navigate to Routes tab
                    metro.findRoutes();
                    MainNavigation.navKey.currentState?.switchToTab(1);
                  },
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Find Routes',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(
      BuildContext context, Map<String, dynamic> insights) {
    final isPeak = insights['isPeakHour'] as bool;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPeak
              ? [const Color(0xFF3D1C1C), const Color(0xFF2D1515)]
              : [const Color(0xFF1C2D1C), const Color(0xFF152D15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPeak
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPeak ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: isPeak ? AppColors.warning : AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isPeak ? '🔴 Peak Hours Active' : '🟢 Off-Peak Hours',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _insightRow(Icons.access_time, 'Best Time',
              insights['bestTimeToTravel'] as String),
          const SizedBox(height: 8),
          _insightRow(Icons.info_outline, 'Alert',
              insights['avoidMessage'] as String),
          const SizedBox(height: 8),
          _insightRow(Icons.lightbulb_outline, 'Tip',
              insights['recommendation'] as String),
        ],
      ),
    );
  }

  Widget _insightRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(
      BuildContext context, TicketProvider tickets, MetroProvider metro) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => MainNavigation.navKey.currentState?.switchToTab(4),
            child: _statCard(
              context,
              icon: Icons.confirmation_num_rounded,
              label: 'Total Trips',
              value: '${tickets.totalTrips}',
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => MainNavigation.navKey.currentState?.switchToTab(4),
            child: _statCard(
              context,
              icon: Icons.currency_rupee_rounded,
              label: 'Total Spent',
              value: '₹${tickets.totalSpent}',
              color: AppColors.aquaLine,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => MainNavigation.navKey.currentState?.switchToTab(2),
            child: _statCard(
              context,
              icon: Icons.train_rounded,
              label: 'Lines',
              value: '${metro.lines.length}',
              color: AppColors.yellowLine,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveETA(BuildContext context, MetroProvider metro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '⏱ Live Train ETA',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MetroScheduleScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Text('Timetable', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Based on official Mumbai Metro frequencies',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: metro.lines.length,
            separatorBuilder: (_, i) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final line = metro.lines[index];
              final eta = metro.getNextTrainETA(line.id);
              final minutes = eta['minutes'] as int;

              return Container(
                width: 160,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: line.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: line.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            line.shortName,
                            style: TextStyle(
                              color: line.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      minutes < 0
                          ? 'Service Ended'
                          : minutes == 0
                              ? 'Arriving Now'
                              : '$minutes min',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: minutes < 0 ? 13 : 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Next: ${eta['nextTrain']}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularStations(
      BuildContext context, MetroProvider metro, CrowdProvider crowd) {
    final stations = metro.popularStations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📍 Popular Stations',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        ...stations.map((station) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: MetroData().getLineColor(station.lineId),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          MetroData().getLine(station.lineId)?.name ?? '',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          crowd.getCrowdColor(station.id).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          crowd.getCrowdIcon(station.id),
                          color: crowd.getCrowdColor(station.id),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            crowd.getCrowdText(station.id),
                            style: TextStyle(
                              color: crowd.getCrowdColor(station.id),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCrowdAlerts(BuildContext context, CrowdProvider crowd) {
    final crowded = crowd.mostCrowdedStations;
    if (crowded.isEmpty) return const SizedBox.shrink();

    final metroData = MetroData();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚠️ Crowd Alerts',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: crowded.take(3).map((entry) {
              final station = metroData.findStationById(entry.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        station?.name ?? entry.key,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'HIGH',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // LIVE ANNOUNCEMENTS CARD
  // ═══════════════════════════════════════════════════════
  Widget _buildLiveAnnouncements(BuildContext context) {
    final admin = context.read<AdminProvider>();
    return StreamBuilder<QuerySnapshot>(
      stream: admin.activeAnnouncementsStream,
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D1515), Color(0xFF1E2440)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.campaign_rounded,
                            color: AppColors.error, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('🔴 Live Alerts',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${docs.length} active',
                            style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...docs.take(3).map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final cat = data['category'] ?? 'General';
                    final lineId = data['line'] ?? '';
                    final lineColors = {
                      'blue': AppColors.blueLine,
                      'yellow': AppColors.yellowLine,
                      'red': AppColors.redLine,
                      'aqua': AppColors.aquaLine,
                    };
                    final lineNames = {
                      'blue': 'Blue Line',
                      'yellow': 'Yellow Line',
                      'red': 'Red Line',
                      'aqua': 'Aqua Line',
                    };
                    final catIcon = switch (cat) {
                      'Delay' => Icons.schedule_rounded,
                      'Cancellation' => Icons.cancel_rounded,
                      _ => Icons.info_rounded,
                    };
                    final catColor = switch (cat) {
                      'Delay' => AppColors.warning,
                      'Cancellation' => AppColors.error,
                      _ => AppColors.info,
                    };

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(catIcon, color: catColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['message'] ?? '',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: catColor
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(cat,
                                          style: TextStyle(
                                              color: catColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: (lineColors[lineId] ??
                                                AppColors.textMuted)
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                          lineNames[lineId] ?? lineId,
                                          style: TextStyle(
                                              color: lineColors[lineId] ??
                                                  AppColors.textMuted,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  // ADMIN-DRIVEN PEAK HOUR BADGES
  // ═══════════════════════════════════════════════════════
  Widget _buildAdminPeakHours(BuildContext context, MetroProvider metro) {
    final admin = context.read<AdminProvider>();
    return StreamBuilder<DocumentSnapshot>(
      stream: admin.peakHoursStream,
      builder: (ctx, snap) {
        final data =
            (snap.data?.data() as Map<String, dynamic>?) ?? {};
        // Determine which lines are relevant to the user
        final userLines = <String>{};
        if (metro.sourceStation != null) {
          userLines.add(metro.sourceStation!.lineId);
        }
        if (metro.destinationStation != null) {
          userLines.add(metro.destinationStation!.lineId);
        }
        // If no station selected, show all active peaks
        final linesToShow = userLines.isEmpty
            ? data.keys
                .where((k) => data[k] == true)
                .toList()
            : userLines
                .where((l) => data[l] == true)
                .toList();

        if (linesToShow.isEmpty) return const SizedBox.shrink();

        final lineNames = {
          'blue': 'Blue Line',
          'yellow': 'Yellow Line',
          'red': 'Red Line',
          'aqua': 'Aqua Line',
        };
        final lineColors = {
          'blue': AppColors.blueLine,
          'yellow': AppColors.yellowLine,
          'red': AppColors.redLine,
          'aqua': AppColors.aquaLine,
        };

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: linesToShow.map((lineId) {
              final color = lineColors[lineId] ?? AppColors.warning;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: color, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '⚡ ${lineNames[lineId]} — Peak Hour',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _openStationSearch(BuildContext context, bool isSource) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StationSearchScreen(isSource: isSource),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SOS BOTTOM SHEET & LOGIC
  // ═══════════════════════════════════════════════════════════

  void _showSOSBottomSheet(BuildContext context, AppAuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Emergency SOS', style: TextStyle(color: AppColors.error, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Tap a number to call immediately.', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 24),
                  
                  // Helplines
                  _buildSOSRow('Police', '100', Icons.local_police_rounded),
                  _buildSOSRow('Women Helpline', '1091', Icons.pregnant_woman_rounded),
                  _buildSOSRow('Metro Helpline', '18001234567', Icons.train_rounded),
                  
                  const Divider(color: AppColors.surfaceLight, height: 32),
                  
                  // Emergency Contact
                  const Text('My Emergency Contact', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  
                  StreamBuilder<DocumentSnapshot>(
                    stream: auth.userProfileStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data?.data() == null) {
                        return _buildAddContactButton(context, auth);
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final contact = data['emergencyContact'] as Map<String, dynamic>?;
                      
                      if (contact == null || contact['phone'] == null || contact['phone'].toString().isEmpty) {
                        return _buildAddContactButton(context, auth);
                      }
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.person, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(contact['name'] ?? 'Saved Contact', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                  Text(contact['phone'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _makePhoneCall(contact['phone']),
                              icon: const Icon(Icons.call, color: AppColors.success),
                              style: IconButton.styleFrom(backgroundColor: AppColors.success.withValues(alpha: 0.1)),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Share Location
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareLocation(context, auth),
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Share My Location via SMS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildSOSRow(String name, String number, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _makePhoneCall(number),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 16),
              Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.call, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text(number, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddContactButton(BuildContext context, AppAuthProvider auth) {
    return InkWell(
      onTap: () => _showAddContactDialog(context, auth),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Emergency Contact', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, AppAuthProvider auth) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Contact', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                auth.saveEmergencyContact(nameCtrl.text.trim(), phoneCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      )
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _shareLocation(BuildContext context, AppAuthProvider auth) async {
    // 1. Get contact from Firestore
    final doc = await auth.userProfileStream?.first;
    if (doc == null || !doc.exists) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add an emergency contact first.')));
      return;
    }
    final data = doc.data() as Map<String, dynamic>;
    final contact = data['emergencyContact'] as Map<String, dynamic>?;
    if (contact == null || contact['phone'] == null) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add an emergency contact first.')));
      return;
    }

    // 2. Get Location
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching location...')));
    }

    final position = await Geolocator.getCurrentPosition();
    final mapsLink = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    final message = 'SOS! I need help. My current location is: $mapsLink';
    
    // 3. Send SMS
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: contact['phone'],
      queryParameters: <String, String>{
        'body': message,
      },
    );
    
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open SMS app.')));
    }
  }
}
