import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/metro_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// CrowdProvider manages real-time crowd levels for all metro stations.
///
/// ROOT CAUSE OF STALE DATA (fixed here):
/// The Firestore `station_status` collection requires `request.auth != null`
/// per Firestore Security Rules. The provider was created at app boot BEFORE
/// authentication completed, so the initial `.snapshots()` subscription fired
/// before the user was authenticated — causing a silent permission-denied error.
/// The stream then entered a permanent error/closed state, and subsequent admin
/// changes were never received. The data only refreshed on `flutter run` because
/// that created a fresh, post-authentication subscription.
///
/// FIX: The provider exposes `onAuthChanged(isLoggedIn)` which is called by
/// `ChangeNotifierProxyProvider` in main.dart whenever auth state changes.
/// When the user logs in, the Firestore subscription is (re-)established with
/// valid credentials. When the user logs out, the subscription is cancelled and
/// all crowd data is cleared — preventing stale cached data.
class CrowdProvider extends ChangeNotifier {
  /// Crowd levels sourced ONLY from Firestore admin overrides.
  /// Stations NOT in this map have no admin-set crowd level (treated as low / no alert).
  final Map<String, CrowdLevel> _adminCrowdLevels = {};

  /// Local user-reported crowd levels (lower priority than admin overrides).
  final Map<String, CrowdLevel> _userReportedLevels = {};

  final Map<String, List<CrowdReport>> _crowdReports = {};
  final Map<String, Map<String, bool>> _stationFacilities = {};
  final MetroData _metroData = MetroData();

  StreamSubscription<QuerySnapshot>? _stationStatusSub;
  bool _isSubscribed = false;

  CrowdProvider();

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUTH LIFECYCLE — called by ProxyProvider in main.dart
  // ─────────────────────────────────────────────────────────────────────────

  /// Called whenever the auth state changes.
  /// - On login  → (re-)subscribe to Firestore with valid auth credentials.
  /// - On logout → cancel subscription & clear all cached crowd data.
  void onAuthChanged({required bool isLoggedIn}) {
    if (isLoggedIn) {
      _subscribeToAdminOverrides();
    } else {
      _cancelSubscription();
      _clearAllData();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIRESTORE REAL-TIME LISTENER
  // ─────────────────────────────────────────────────────────────────────────

  /// Subscribes to the `station_status` collection.
  /// Rebuilds `_adminCrowdLevels` from scratch on every snapshot so that:
  ///   • Stations reset to LOW by admin disappear from the alert banner.
  ///   • Documents deleted by admin are immediately reflected.
  ///   • No stale data is ever kept in memory.
  void _subscribeToAdminOverrides() {
    // Avoid duplicate subscriptions
    if (_isSubscribed) return;

    _cancelSubscription(); // Safety: cancel any prior zombie subscription

    _stationStatusSub = FirebaseFirestore.instance
        .collection('station_status')
        .snapshots()
        .listen(
      (snapshot) {
        // ── Rebuild from scratch on every event ──
        _adminCrowdLevels.clear();
        _stationFacilities.clear();

        for (final doc in snapshot.docs) {
          final data = doc.data();

          // Parse crowd level (admin slider: 1 = empty, 5 = overcrowded)
          if (data.containsKey('crowdLevel')) {
            final levelInt = (data['crowdLevel'] as num?)?.toInt() ?? 1;
            final CrowdLevel newLevel;
            if (levelInt <= 1) {
              newLevel = CrowdLevel.low;
            } else if (levelInt == 2) {
              newLevel = CrowdLevel.medium;
            } else {
              // 3, 4, 5 → HIGH  (CrowdLevel only has 3 visible states)
              newLevel = CrowdLevel.high;
            }
            _adminCrowdLevels[doc.id] = newLevel;
          }

          // Parse facility statuses
          if (data.containsKey('facilities')) {
            try {
              _stationFacilities[doc.id] =
                  Map<String, bool>.from(data['facilities'] as Map);
            } catch (_) {
              // Malformed data — skip silently
            }
          }
        }

        notifyListeners();
      },
      onError: (Object error) {
        // Log but do not crash. Will retry on next login via onAuthChanged.
        debugPrint('CrowdProvider ▶ Firestore listener error: $error');
        _isSubscribed = false;
      },
      onDone: () {
        _isSubscribed = false;
      },
    );

    _isSubscribed = true;
  }

  void _cancelSubscription() {
    _stationStatusSub?.cancel();
    _stationStatusSub = null;
    _isSubscribed = false;
  }

  void _clearAllData() {
    _adminCrowdLevels.clear();
    _userReportedLevels.clear();
    _crowdReports.clear();
    _stationFacilities.clear();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Full crowd level map — admin overrides take priority over user reports.
  Map<String, CrowdLevel> get stationCrowdLevels {
    final merged = <String, CrowdLevel>{};

    // Default every station to low
    for (final line in _metroData.lines) {
      for (final station in line.stations) {
        merged[station.id] = CrowdLevel.low;
      }
    }

    // Layer in user-reported levels (lower priority)
    merged.addAll(_userReportedLevels);

    // Layer in admin overrides (highest priority — overwrites everything)
    merged.addAll(_adminCrowdLevels);

    return merged;
  }

  Map<String, bool> getFacilities(String stationId) =>
      _stationFacilities[stationId] ?? {};

  CrowdLevel getCrowdLevel(String stationId) {
    if (_adminCrowdLevels.containsKey(stationId)) {
      return _adminCrowdLevels[stationId]!;
    }
    if (_userReportedLevels.containsKey(stationId)) {
      return _userReportedLevels[stationId]!;
    }
    return CrowdLevel.low;
  }

  Color getCrowdColor(String stationId) {
    switch (getCrowdLevel(stationId)) {
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
    switch (getCrowdLevel(stationId)) {
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
    switch (getCrowdLevel(stationId)) {
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

  // ─────────────────────────────────────────────────────────────────────────
  // USER REPORTING
  // ─────────────────────────────────────────────────────────────────────────

  void reportCrowd(String stationId, CrowdLevel level) {
    _userReportedLevels[stationId] = level;

    _crowdReports.putIfAbsent(stationId, () => []);
    _crowdReports[stationId]!.add(CrowdReport(
      stationId: stationId,
      level: level,
      reportedAt: DateTime.now(),
    ));

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DERIVED DATA
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns only stations explicitly set to HIGH by the admin.
  /// This is the ONLY source for the Crowd Alert banner on the Home screen.
  /// User-reported levels are intentionally excluded to prevent false alerts.
  List<MapEntry<String, CrowdLevel>> get mostCrowdedStations {
    return _adminCrowdLevels.entries
        .where((e) => e.value == CrowdLevel.high)
        .take(5)
        .toList();
  }

  List<MapEntry<String, CrowdLevel>> get leastCrowdedStations {
    return stationCrowdLevels.entries
        .where((e) => e.value == CrowdLevel.low)
        .take(5)
        .toList();
  }

  Map<String, dynamic> getInsights() {
    final hour = DateTime.now().hour;
    final isPeakMorning = hour >= 8 && hour <= 10;
    final isPeakEvening = hour >= 17 && hour <= 20;
    final isPeak = isPeakMorning || isPeakEvening;

    final String bestTimeToTravel;
    final String avoidMessage;
    final String recommendation;

    if (isPeakMorning) {
      bestTimeToTravel = 'After 10:30 AM';
      avoidMessage = 'Avoid Andheri, Ghatkopar & Dadar now';
      recommendation =
          'Peak morning rush. Consider travelling after 10:30 AM for a comfortable journey.';
    } else if (isPeakEvening) {
      bestTimeToTravel = 'After 8:30 PM';
      avoidMessage = 'Avoid major interchange stations';
      recommendation =
          'Evening rush hour. Trains are crowded at interchange stations.';
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
      'peakType':
          isPeakMorning ? 'morning' : (isPeakEvening ? 'evening' : 'off-peak'),
    };
  }
}
