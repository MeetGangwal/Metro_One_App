import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/metro_provider.dart';
import '../../core/models/models.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Station? _fromStation;
  Station? _toStation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_fromStation != null || _toStation != null) {
        setState(() {
          _fromStation = null;
          _toStation = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Calculate upcoming trains for a given line between two stations.
  /// Returns a list of maps with 'departureFrom', 'arrivalTo', and 'travelMin'.
  List<Map<String, dynamic>> _calculateUpcomingTrains(
      MetroLine line, String firstTrain, String lastTrain, int frequency) {
    if (_fromStation == null || _toStation == null) return [];
    if (_fromStation!.lineId != line.id || _toStation!.lineId != line.id) {
      return [];
    }

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    // Parse service window
    final firstParts = firstTrain.split(':');
    final lastParts = lastTrain.split(':');
    final firstTrainMin =
        int.parse(firstParts[0]) * 60 + int.parse(firstParts[1]);
    final lastTrainMin =
        int.parse(lastParts[0]) * 60 + int.parse(lastParts[1]);

    final fromIdx = _fromStation!.index;
    final toIdx = _toStation!.index;
    final stopsCount = (toIdx - fromIdx).abs();
    final travelMinutes = (stopsCount * 2.5).ceil();

    // Determine direction: forward (index ascending) or reverse
    final isForward = toIdx > fromIdx;

    // Time offset from terminus to the "From" station
    // If forward, departure from first station (index 0) is the base time.
    // The train reaches station at index N after N * 2.5 min.
    // If reverse, departure from last station (index max) is the base time.
    final int fromStationOffset;
    if (isForward) {
      fromStationOffset = (fromIdx * 2.5).ceil();
    } else {
      final lastIdx = line.stations.length - 1;
      fromStationOffset = ((lastIdx - fromIdx) * 2.5).ceil();
    }

    // Generate all train departure times from the terminus
    final trains = <Map<String, dynamic>>[];
    int trainTime = firstTrainMin;

    while (trainTime <= lastTrainMin) {
      // Calculate when THIS train arrives at the "From" station
      final arrivalAtFrom = trainTime + fromStationOffset;
      // Calculate when it arrives at the "To" station
      final arrivalAtTo = arrivalAtFrom + travelMinutes;

      // Only show trains that haven't passed the "From" station yet
      if (arrivalAtFrom >= nowMinutes && arrivalAtTo <= lastTrainMin + 60) {
        trains.add({
          'departureFrom': _formatTime(arrivalAtFrom),
          'arrivalTo': _formatTime(arrivalAtTo),
          'travelMin': travelMinutes,
          'minutesAway': arrivalAtFrom - nowMinutes,
        });
      }

      // Stop after collecting 10 upcoming trains
      if (trains.length >= 10) break;

      trainTime += frequency;
    }

    return trains;
  }

  String _formatTime(int totalMinutes) {
    final h = (totalMinutes ~/ 60) % 24;
    final m = totalMinutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0
        ? 12
        : h > 12
            ? h - 12
            : h;
    return '${hour12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final metro = context.watch<MetroProvider>();
    final lines = metro.lines;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Train Timetable',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Search trains like m-indicator',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),

            // Line Selector Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: lines[_tabController.index].color
                      .withValues(alpha: 0.2),
                ),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w400),
                padding: const EdgeInsets.all(4),
                tabs: lines.map((line) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                        Text(line.shortName),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: lines.map((line) {
                  return _buildLineTab(context, line);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineTab(BuildContext context, MetroLine line) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('timetable').doc(line.id).snapshots(),
      builder: (context, snapshot) {
        String firstTrain = line.firstTrain;
        String lastTrain = line.lastTrain;
        int frequency = line.frequencyMinutes;

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['_line_config'] != null) {
            final config = data['_line_config'] as Map<String, dynamic>;
            firstTrain = config['firstTrain'] ?? firstTrain;
            lastTrain = config['lastTrain'] ?? lastTrain;
            frequency = config['frequency'] ?? frequency;
          }
        }

        final trains = _calculateUpcomingTrains(line, firstTrain, lastTrain, frequency);
        final stopsCount = (_fromStation != null && _toStation != null)
            ? (_toStation!.index - _fromStation!.index).abs()
            : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line Info Bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: line.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: line.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: line.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.train_rounded,
                          color: line.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.name,
                            style: TextStyle(
                              color: line.color,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${line.stations.first.name} ↔ ${line.stations.last.name}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Every $frequency min',
                          style: TextStyle(
                            color: line.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$firstTrain - $lastTrain',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // Station Selectors
          _buildStationSelector(
            context,
            label: 'FROM',
            value: _fromStation,
            stations: line.stations,
            dotColor: AppColors.success,
            onChanged: (station) {
              setState(() {
                _fromStation = station;
                // Reset "To" if same as "From"
                if (_toStation == station) _toStation = null;
              });
            },
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),

          // Connector dots + swap
          Row(
            children: [
              const SizedBox(width: 24),
              Column(
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 2,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const Spacer(),
              if (_fromStation != null && _toStation != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final temp = _fromStation;
                      _fromStation = _toStation;
                      _toStation = temp;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
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

          _buildStationSelector(
            context,
            label: 'TO',
            value: _toStation,
            stations: line.stations,
            dotColor: AppColors.error,
            excludeStation: _fromStation,
            onChanged: (station) {
              setState(() => _toStation = station);
            },
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // Results
          if (_fromStation != null && _toStation != null) ...[
            // Journey summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    line.color.withValues(alpha: 0.08),
                    line.color.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: line.color.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _summaryChip(Icons.pin_drop_rounded, '$stopsCount stops', line.color)),
                  Container(width: 1, height: 28, color: AppColors.textMuted.withValues(alpha: 0.1)),
                  Expanded(child: _summaryChip(Icons.access_time_rounded, '${(stopsCount * 2.5).ceil()} min', line.color)),
                  Container(width: 1, height: 28, color: AppColors.textMuted.withValues(alpha: 0.1)),
                  Expanded(child: _summaryChip(Icons.currency_rupee_rounded, '₹${_calculateFare(stopsCount)}', line.color)),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

            const SizedBox(height: 20),

            // Upcoming trains header
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Trains',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${trains.length} trains',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 12),

            // Train list
            if (trains.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.nightlight_round,
                          color: AppColors.textMuted, size: 40),
                      SizedBox(height: 12),
                      Text(
                        'No more trains today',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Service has ended for this route.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms)
            else
              ...trains.asMap().entries.map((entry) {
                final i = entry.key;
                final train = entry.value;
                final isNext = i == 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isNext
                        ? line.color.withValues(alpha: 0.08)
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isNext
                          ? line.color.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Train number badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isNext
                              ? line.color.withValues(alpha: 0.2)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.train_rounded,
                            color: isNext ? line.color : AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Departure time at "From"
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              train['departureFrom'] as String,
                              style: TextStyle(
                                color: isNext
                                    ? line.color
                                    : AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _fromStation!.name,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Arrow + travel time
                      Column(
                        children: [
                          const Icon(Icons.arrow_forward_rounded,
                              color: AppColors.textMuted, size: 14),
                          Text(
                            '${train['travelMin']}m',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Arrival time at "To"
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              train['arrivalTo'] as String,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _toStation!.name,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // "Minutes away" badge
                      if (isNext)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: line.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${train['minutesAway']}m',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: (400 + i * 60).ms).slideX(
                    begin: 0.03, end: 0);
              }),

            const SizedBox(height: 24),
          ] else ...[
            // Empty state
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      size: 56,
                      color: AppColors.textMuted.withValues(alpha: 0.25)),
                  const SizedBox(height: 16),
                  const Text(
                    'Select stations above\nto view upcoming trains',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ],
      ),
    );
      }
    );
  }

  Widget _buildStationSelector(
    BuildContext context, {
    required String label,
    required Station? value,
    required List<Station> stations,
    required Color dotColor,
    required ValueChanged<Station?> onChanged,
    Station? excludeStation,
  }) {
    // Filter out the excluded station
    final available = excludeStation == null
        ? stations
        : stations.where((s) => s.id != excludeStation.id).toList();

    final safeValue = value != null && available.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: safeValue != null
              ? dotColor.withValues(alpha: 0.4)
              : AppColors.textMuted.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$label  ',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Station>(
                value: safeValue,
                hint: Text(
                  'Select $label station',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted, size: 20),
                dropdownColor: AppColors.surface,
                isExpanded: true,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                items: available.map((station) {
                  return DropdownMenuItem<Station>(
                    value: station,
                    child: Text(
                      station.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  int _calculateFare(int stops) {
    if (stops <= 0) return 0;
    if (stops <= 3) return 10;
    if (stops <= 6) return 20;
    if (stops <= 10) return 30;
    if (stops <= 15) return 40;
    if (stops <= 20) return 50;
    if (stops <= 25) return 60;
    return 70;
  }
}
