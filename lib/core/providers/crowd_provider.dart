import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/metro_data.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class CrowdProvider extends ChangeNotifier {
  final Map<String, CrowdLevel> _stationCrowdLevels = {};
  final Map<String, List<CrowdReport>> _crowdReports = {};
  final Map<String, Map<String, bool>> _stationFacilities = {};
  final MetroData _metroData = MetroData();
  final Random _random = Random();

  CrowdProvider() {
    _initializeDefaultCrowdData();
    _listenToAdminOverrides();
  }

  void _listenToAdminOverrides() {
    FirebaseFirestore.instance
        .collection('station_status')
        .snapshots()
        .listen((snapshot) {
      bool hasChanges = false;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('crowdLevel')) {
          final levelInt = data['crowdLevel'] as int;
          CrowdLevel? newLevel;
          if (levelInt <= 1) newLevel = CrowdLevel.low;
          else if (levelInt == 2) newLevel = CrowdLevel.medium;
          else if (levelInt == 3) newLevel = CrowdLevel.high;
          else if (levelInt >= 4) newLevel = CrowdLevel.high; // We map 4,5 to High for now, as CrowdLevel only has 3 states

          if (newLevel != null) {
            _stationCrowdLevels[doc.id] = newLevel;
            hasChanges = true;
          }
        }
        if (data.containsKey('facilities')) {
          final fac = Map<String, bool>.from(data['facilities'] as Map);
          _stationFacilities[doc.id] = fac;
          hasChanges = true;
        }
      }
      if (hasChanges) {
        notifyListeners();
      }
    });
  }

  Map<String, CrowdLevel> get stationCrowdLevels => _stationCrowdLevels;
  
  Map<String, bool> getFacilities(String stationId) {
    return _stationFacilities[stationId] ?? {};
  }

  void _initializeDefaultCrowdData() {
    // Set realistic default crowd levels based on Mumbai metro usage
    final now = DateTime.now();
    final hour = now.hour;
    final isPeakHour = (hour >= 8 && hour <= 10) || (hour >= 17 && hour <= 20);

    for (final line in _metroData.lines) {
      for (final station in line.stations) {
        CrowdLevel level;

        // High traffic stations
        final highTrafficStations = [
          'Andheri', 'Ghatkopar', 'CSMT', 'Dadar',
          'BKC', 'Churchgate', 'Worli',
        ];

        final mediumTrafficStations = [
          'Versova', 'D.N. Nagar', 'WEH', 'Marol Naka',
          'Borivali West', 'Kandivali West', 'Malad West',
          'Goregaon East', 'Siddhivinayak',
        ];

        if (highTrafficStations.contains(station.name)) {
          level = isPeakHour ? CrowdLevel.high : CrowdLevel.medium;
        } else if (mediumTrafficStations.contains(station.name)) {
          level = isPeakHour ? CrowdLevel.medium : CrowdLevel.low;
        } else {
          level = isPeakHour
              ? (CrowdLevel.values[_random.nextInt(2) + 1]) // medium or high
              : CrowdLevel.low;
        }

        _stationCrowdLevels[station.id] = level;
      }
    }
  }

  CrowdLevel getCrowdLevel(String stationId) {
    return _stationCrowdLevels[stationId] ?? CrowdLevel.unknown;
  }

  Color getCrowdColor(String stationId) {
    final level = getCrowdLevel(stationId);
    switch (level) {
      case CrowdLevel.low:
        return const Color(0xFF00E676);
      case CrowdLevel.medium:
        return const Color(0xFFFFAB00);
      case CrowdLevel.high:
        return const Color(0xFFFF5252);
      case CrowdLevel.unknown:
        return Colors.grey;
    }
  }

  String getCrowdText(String stationId) {
    final level = getCrowdLevel(stationId);
    switch (level) {
      case CrowdLevel.low:
        return 'Low';
      case CrowdLevel.medium:
        return 'Medium';
      case CrowdLevel.high:
        return 'High';
      case CrowdLevel.unknown:
        return 'Unknown';
    }
  }

  IconData getCrowdIcon(String stationId) {
    final level = getCrowdLevel(stationId);
    switch (level) {
      case CrowdLevel.low:
        return Icons.person;
      case CrowdLevel.medium:
        return Icons.people;
      case CrowdLevel.high:
        return Icons.groups;
      case CrowdLevel.unknown:
        return Icons.question_mark;
    }
  }

  void reportCrowd(String stationId, CrowdLevel level) {
    _stationCrowdLevels[stationId] = level;

    final report = CrowdReport(
      stationId: stationId,
      level: level,
      reportedAt: DateTime.now(),
    );

    _crowdReports.putIfAbsent(stationId, () => []);
    _crowdReports[stationId]!.add(report);

    notifyListeners();
  }

  /// Get most crowded stations
  List<MapEntry<String, CrowdLevel>> get mostCrowdedStations {
    final highCrowd = _stationCrowdLevels.entries
        .where((e) => e.value == CrowdLevel.high)
        .toList();
    return highCrowd.take(5).toList();
  }

  /// Get least crowded stations
  List<MapEntry<String, CrowdLevel>> get leastCrowdedStations {
    final lowCrowd = _stationCrowdLevels.entries
        .where((e) => e.value == CrowdLevel.low)
        .toList();
    return lowCrowd.take(5).toList();
  }

  /// Smart insights
  Map<String, dynamic> getInsights() {
    final now = DateTime.now();
    final hour = now.hour;
    final isPeakMorning = hour >= 8 && hour <= 10;
    final isPeakEvening = hour >= 17 && hour <= 20;
    final isPeak = isPeakMorning || isPeakEvening;

    String bestTimeToTravel;
    String avoidMessage;
    String recommendation;

    if (isPeakMorning) {
      bestTimeToTravel = 'After 10:30 AM';
      avoidMessage = 'Avoid Andheri, Ghatkopar & Dadar now';
      recommendation = 'Peak morning rush. Consider travelling after 10:30 AM for a comfortable journey.';
    } else if (isPeakEvening) {
      bestTimeToTravel = 'After 8:30 PM';
      avoidMessage = 'Avoid major interchange stations';
      recommendation = 'Evening rush hour. Trains are crowded at interchange stations.';
    } else if (hour < 8) {
      bestTimeToTravel = 'Now is a great time!';
      avoidMessage = 'All stations are relatively empty';
      recommendation = 'Early morning - enjoy a peaceful commute!';
    } else if (hour >= 10 && hour < 17) {
      bestTimeToTravel = 'Current time is good';
      avoidMessage = 'No major crowd alerts';
      recommendation = 'Off-peak hours. Comfortable travel expected.';
    } else {
      bestTimeToTravel = 'Now is fine';
      avoidMessage = 'Crowd is reducing';
      recommendation = 'Late evening - trains are getting less crowded.';
    }

    return {
      'isPeakHour': isPeak,
      'bestTimeToTravel': bestTimeToTravel,
      'avoidMessage': avoidMessage,
      'recommendation': recommendation,
      'peakType': isPeakMorning ? 'morning' : (isPeakEvening ? 'evening' : 'off-peak'),
    };
  }
}
