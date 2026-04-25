import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/crowd_provider.dart';
import '../../core/data/metro_data.dart';
import '../../core/models/models.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  String? _selectedLineId;
  final MetroData _metroData = MetroData();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crowd = context.watch<CrowdProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Metro Map',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // Line filter tabs
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                onTap: (index) {
                  setState(() {
                    if (index == 0) {
                      _selectedLineId = null;
                    } else {
                      _selectedLineId = _metroData.lines[index - 1].id;
                    }
                  });
                },
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: [
                  const Tab(text: 'All Lines'),
                  ..._metroData.lines.map((line) => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: line.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(line.shortName),
                          ],
                        ),
                      )),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            // Map
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildMetroMapView(crowd),
                ),
              ),
            ),

            // Legend
            _buildLegend().animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildMetroMapView(CrowdProvider crowd) {
    final linesToShow = _selectedLineId != null
        ? [_metroData.getLine(_selectedLineId!)!]
        : _metroData.lines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: linesToShow.map((line) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: line.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: line.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: line.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${line.name} (${line.shortName})',
                      style: TextStyle(
                        color: line.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${line.stations.length} stations',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Timing info
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _timingChip('First', line.firstTrain, Icons.wb_sunny_outlined),
                    const SizedBox(width: 12),
                    _timingChip('Last', line.lastTrain, Icons.nightlight_outlined),
                    const SizedBox(width: 12),
                    _timingChip('Every', '${line.frequencyMinutes} min', Icons.timer_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Stations
              ...line.stations.asMap().entries.map((entry) {
                final i = entry.key;
                final station = entry.value;
                final isFirst = i == 0;
                final isLast = i == line.stations.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline line
                    SizedBox(
                      width: 30,
                      child: Column(
                        children: [
                          Container(
                            width: isFirst || isLast || station.isInterchange ? 16 : 10,
                            height: isFirst || isLast || station.isInterchange ? 16 : 10,
                            decoration: BoxDecoration(
                              color: isFirst || isLast
                                  ? line.color
                                  : station.isInterchange
                                      ? AppColors.warning
                                      : Colors.transparent,
                              border: Border.all(color: line.color, width: 2.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 3,
                              height: 28,
                              decoration: BoxDecoration(
                                color: line.color.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Station info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.name,
                                    style: TextStyle(
                                      color: isFirst || isLast
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontSize: isFirst || isLast ? 14 : 13,
                                      fontWeight: isFirst || isLast
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  if (station.isInterchange)
                                    Text(
                                      '🔄 Interchange: ${station.connectedLineIds.map((id) => _metroData.getLine(id)?.shortName ?? id).join(', ')}',
                                      style: const TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Report crowd button
                            GestureDetector(
                              onTap: () => _showCrowdReportDialog(context, station),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: crowd.getCrowdColor(station.id).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      crowd.getCrowdIcon(station.id),
                                      color: crowd.getCrowdColor(station.id),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      crowd.getCrowdText(station.id),
                                      style: TextStyle(
                                        color: crowd.getCrowdColor(station.id),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _timingChip(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 14),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(AppColors.crowdLow, 'Low'),
          _legendItem(AppColors.crowdMedium, 'Medium'),
          _legendItem(AppColors.crowdHigh, 'High'),
          _legendItem(AppColors.warning, 'Interchange'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }


  void _showCrowdReportDialog(BuildContext context, Station station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Report Crowd at ${station.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Help other commuters by reporting current crowd level',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _crowdButton(ctx, station.id, CrowdLevel.low, '😊', 'Low', AppColors.crowdLow),
                  const SizedBox(width: 12),
                  _crowdButton(ctx, station.id, CrowdLevel.medium, '😐', 'Medium', AppColors.crowdMedium),
                  const SizedBox(width: 12),
                  _crowdButton(ctx, station.id, CrowdLevel.high, '😰', 'High', AppColors.crowdHigh),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _crowdButton(BuildContext ctx, String stationId, CrowdLevel level,
      String emoji, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ctx.read<CrowdProvider>().reportCrowd(stationId, level);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thanks for reporting! Crowd marked as $label'),
              backgroundColor: AppColors.surfaceLight,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
