
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/transit_alarm_provider.dart';
import '../../core/data/metro_data.dart';
import '../../core/models/models.dart';

class TransitAlarmScreen extends StatefulWidget {
  const TransitAlarmScreen({super.key});

  @override
  State<TransitAlarmScreen> createState() => _TransitAlarmScreenState();
}

class _TransitAlarmScreenState extends State<TransitAlarmScreen>
    with TickerProviderStateMixin {
  Station? _selectedSource;
  Station? _selectedDest;
  MetroRoute? _previewRoute;
  List<MetroRoute> _previewRoutes = [];

  late AnimationController _pulseController;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void _resolvePreview() {
    if (_selectedSource != null && _selectedDest != null) {
      final routes = MetroData().findRoutes(_selectedSource!, _selectedDest!);
      setState(() {
        _previewRoutes = routes;
        _previewRoute = routes.isNotEmpty ? routes.first : null;
      });
    } else {
      setState(() {
        _previewRoutes = [];
        _previewRoute = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarm = context.watch<TransitAlarmProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Smart Transit Alarm'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (alarm.phase != AlarmPhase.idle &&
              alarm.phase != AlarmPhase.completed)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              tooltip: 'Cancel Alarm',
              onPressed: () => _confirmCancel(context, alarm),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _buildPhaseContent(alarm),
        ),
      ),
    );
  }

  Widget _buildPhaseContent(TransitAlarmProvider alarm) {
    switch (alarm.phase) {
      case AlarmPhase.idle:
        return _buildIdlePhase(alarm);
      case AlarmPhase.leg1Active:
      case AlarmPhase.leg2Active:
        return _buildCountdownPhase(alarm);
      case AlarmPhase.awaitingInterchangeConfirm:
        return _buildInterchangePrompt(alarm);
      case AlarmPhase.completed:
        return _buildCompletedPhase(alarm);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  IDLE PHASE — Station picker + Set Alarm
  // ════════════════════════════════════════════════════════════════

  Widget _buildIdlePhase(TransitAlarmProvider alarm) {
    return Column(
      children: [
        // Hero Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.aquaLine.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.alarm_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 14),
              const Text(
                'Set Your Transit Alarm',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Get notified 5 minutes before your station arrives.\nWorks for direct & interchange journeys.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 24),

        // Source station
        _stationSelector(
          label: 'Source Station',
          icon: Icons.trip_origin_rounded,
          iconColor: AppColors.success,
          station: _selectedSource,
          onSelect: (s) {
            setState(() => _selectedSource = s);
            _resolvePreview();
          },
        ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05, end: 0),

        const SizedBox(height: 12),

        // Swap button
        Center(
          child: GestureDetector(
            onTap: () {
              final temp = _selectedSource;
              setState(() {
                _selectedSource = _selectedDest;
                _selectedDest = temp;
              });
              _resolvePreview();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(Icons.swap_vert_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
        ).animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 12),

        // Destination station
        _stationSelector(
          label: 'Destination Station',
          icon: Icons.location_on_rounded,
          iconColor: AppColors.error,
          station: _selectedDest,
          onSelect: (s) {
            setState(() => _selectedDest = s);
            _resolvePreview();
          },
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05, end: 0),

        const SizedBox(height: 20),

        // Route Preview
        if (_previewRoute != null) ...[
          _buildRoutePreview(_previewRoute!),
          const SizedBox(height: 20),
        ],

        // Set Alarm button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: (_selectedSource != null &&
                    _selectedDest != null &&
                    _previewRoute != null)
                ? () {
                    final success = alarm.setAlarm(_selectedSource!, _selectedDest!);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Journey is too short to require an alarm. Enjoy your quick ride!',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF2D6A4F),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.alarm_add_rounded, size: 22),
            label: const Text(
              'Set Alarm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.surfaceLight,
              disabledForegroundColor: AppColors.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _stationSelector({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Station? station,
    required ValueChanged<Station> onSelect,
  }) {
    return GestureDetector(
      onTap: () => _showStationPicker(context, label, onSelect),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: station != null
                ? iconColor.withValues(alpha: 0.3)
                : AppColors.textMuted.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    station?.name ?? 'Tap to select',
                    style: TextStyle(
                      color: station != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 15,
                      fontWeight:
                          station != null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (station != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: MetroData()
                      .getLineColor(station.lineId)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  MetroData().getLine(station.lineId)?.shortName ?? '',
                  style: TextStyle(
                    color: MetroData().getLineColor(station.lineId),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutePreview(MetroRoute route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceCard,
            AppColors.surface.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Route Preview',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (route.interchanges > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${route.interchanges} Interchange',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Direct',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Segments visualization
          ...route.segments.asMap().entries.map((entry) {
            final i = entry.key;
            final seg = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: i < route.segments.length - 1 ? 8 : 0),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: seg.lineColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${seg.stations.first.name} → ${seg.stations.last.name}',
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
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 14),
          Container(
            height: 1,
            color: AppColors.textMuted.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _previewStat(
                  Icons.timer_outlined, '${route.estimatedMinutes} min'),
              _previewStatDivider(),
              _previewStat(
                  Icons.currency_rupee_rounded, '₹${route.fare.toStringAsFixed(0)}'),
              _previewStatDivider(),
              _previewStat(Icons.linear_scale_rounded,
                  '${route.totalStops} stops'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _previewStat(IconData icon, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewStatDivider() {
    return Container(
      width: 1,
      height: 20,
      color: AppColors.textMuted.withValues(alpha: 0.2),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  COUNTDOWN PHASE — Active timer with animated ring
  // ════════════════════════════════════════════════════════════════

  Widget _buildCountdownPhase(TransitAlarmProvider alarm) {
    final isLeg2 = alarm.phase == AlarmPhase.leg2Active;

    return Column(
      children: [
        const SizedBox(height: 16),

        // Leg indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: alarm.currentLegLineColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: alarm.currentLegLineColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: alarm.currentLegLineColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isLeg2 ? 'Leg 2 • ${alarm.currentLegLineName}' : alarm.isInterchangeJourney ? 'Leg 1 • ${alarm.currentLegLineName}' : 'Direct • ${alarm.currentLegLineName}',
                style: TextStyle(
                  color: alarm.currentLegLineColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 12),

        // Route label
        Text(
          alarm.currentLegLabel,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 32),

        // Countdown ring
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: AppColors.surfaceLight,
                ),
              ),
              // Progress ring
              SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: _ringController,
                  builder: (_, __) {
                    return CircularProgressIndicator(
                      value: alarm.progress,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: _getCountdownColor(alarm),
                    );
                  },
                ),
              ),
              // Glow effect
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getCountdownColor(alarm).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Timer text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    alarm.remainingFormatted,
                    style: TextStyle(
                      color: _getCountdownColor(alarm),
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'until notification',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

        const SizedBox(height: 32),

        // Info card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Alarm Active',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                alarm.isInterchangeJourney && !isLeg2
                    ? 'You\'ll be notified when approaching ${alarm.interchangeStation?.name ?? "interchange"}. After switching lines, confirm to start the second timer.'
                    : 'You\'ll be notified 5 minutes before arriving at ${alarm.destStation?.name ?? "destination"}.',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 20),

        // Cancel button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _confirmCancel(context, alarm),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancel Alarm',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 32),
      ],
    );
  }

  Color _getCountdownColor(TransitAlarmProvider alarm) {
    if (alarm.remainingSeconds < 60) return AppColors.error;
    if (alarm.remainingSeconds < 180) return AppColors.warning;
    return AppColors.primary;
  }

  // ════════════════════════════════════════════════════════════════
  //  INTERCHANGE PROMPT — Awaiting user confirmation
  // ════════════════════════════════════════════════════════════════

  Widget _buildInterchangePrompt(TransitAlarmProvider alarm) {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Pulsing alarm icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, child) {
            final scale = 1.0 + (_pulseController.value * 0.08);
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: Colors.white, size: 40),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          '🔄 Interchange Approaching!',
          style: TextStyle(
            color: AppColors.warning,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 8),

        Text(
          'Station "${alarm.interchangeStation?.name}" is arriving.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 32),

        // Interchange check-in card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Switch to the ${alarm.nextLineName ?? "next line"} and board the train.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Have you changed the line\nand boarded the train?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Remaining journey info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.textMuted, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Remaining: ${(alarm.leg2TotalSeconds / 60).ceil()} min to ${alarm.destStation?.name}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Yes / No buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => alarm.cancelAlarm(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('No, Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => alarm.confirmInterchangeBoarded(),
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text('Yes, Boarded!',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.08, end: 0),

        const SizedBox(height: 32),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  COMPLETED PHASE — Success with auto-reset
  // ════════════════════════════════════════════════════════════════

  Widget _buildCompletedPhase(TransitAlarmProvider alarm) {
    return Column(
      children: [
        const SizedBox(height: 48),

        // Checkmark
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 6,
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
        ).animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 600.ms),

        const SizedBox(height: 28),

        const Text(
          '🎉 You\'ve Arrived!',
          style: TextStyle(
            color: AppColors.success,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 8),

        Text(
          'Destination: ${alarm.destStation?.name ?? ""}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 16),

        Text(
          'The alarm has been cleared automatically.',
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ).animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 48),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => alarm.cancelAlarm(),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Set New Alarm',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ).animate().fadeIn(delay: 600.ms),

        const SizedBox(height: 32),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════════

  void _confirmCancel(BuildContext context, TransitAlarmProvider alarm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Alarm?'),
        content: const Text(
            'This will stop the current alarm. You can set a new one anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              alarm.cancelAlarm();
            },
            child: const Text('Cancel Alarm',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showStationPicker(
    BuildContext context,
    String title,
    ValueChanged<Station> onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _StationPickerSheet(
          title: title,
          onSelect: (station) {
            onSelect(station);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Station Picker Bottom Sheet
// ════════════════════════════════════════════════════════════════

class _StationPickerSheet extends StatefulWidget {
  final String title;
  final ValueChanged<Station> onSelect;

  const _StationPickerSheet({
    required this.title,
    required this.onSelect,
  });

  @override
  State<_StationPickerSheet> createState() => _StationPickerSheetState();
}

class _StationPickerSheetState extends State<_StationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Station> _results = [];
  final MetroData _metroData = MetroData();

  @override
  void initState() {
    super.initState();
    // Show all stations grouped by line initially
    _results = _metroData.allStations;
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _results = _metroData.allStations);
    } else {
      setState(() => _results = _metroData.searchStations(query));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: _onSearch,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search stations...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _results.length,
                  itemBuilder: (_, index) {
                    final station = _results[index];
                    final lineColor = _metroData.getLineColor(station.lineId);
                    final lineName =
                        _metroData.getLine(station.lineId)?.shortName ?? '';
                    return GestureDetector(
                      onTap: () => widget.onSelect(station),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: lineColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                station.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: lineColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lineName,
                                style: TextStyle(
                                  color: lineColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (station.isInterchange) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.swap_horiz_rounded,
                                  color: AppColors.warning, size: 16),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}


