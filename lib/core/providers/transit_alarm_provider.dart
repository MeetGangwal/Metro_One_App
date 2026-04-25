import 'dart:async';
import 'package:flutter/material.dart';
import '../data/metro_data.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

/// Phases of the transit alarm state machine
enum AlarmPhase {
  idle,
  leg1Active,
  awaitingInterchangeConfirm,
  leg2Active,
  completed,
}

class TransitAlarmProvider extends ChangeNotifier {
  final MetroData _metroData = MetroData();

  // ─── State ───
  AlarmPhase _phase = AlarmPhase.idle;
  Station? _sourceStation;
  Station? _destStation;
  MetroRoute? _selectedRoute;
  Station? _interchangeStation;
  String? _nextLineName;

  int _leg1TotalSeconds = 0;
  int _leg2TotalSeconds = 0;
  int _remainingSeconds = 0;
  int _currentLegTotalSeconds = 0;

  Timer? _countdownTimer;
  Timer? _autoResetTimer;

  // ─── Getters ───
  AlarmPhase get phase => _phase;
  Station? get sourceStation => _sourceStation;
  Station? get destStation => _destStation;
  MetroRoute? get selectedRoute => _selectedRoute;
  Station? get interchangeStation => _interchangeStation;
  String? get nextLineName => _nextLineName;
  int get remainingSeconds => _remainingSeconds;
  int get currentLegTotalSeconds => _currentLegTotalSeconds;
  int get leg1TotalSeconds => _leg1TotalSeconds;
  int get leg2TotalSeconds => _leg2TotalSeconds;
  MetroData get metroData => _metroData;

  /// Progress from 0.0 (just started) to 1.0 (timer done)
  double get progress {
    if (_currentLegTotalSeconds <= 0) return 0.0;
    return 1.0 - (_remainingSeconds / _currentLegTotalSeconds);
  }

  /// Formatted MM:SS for the countdown
  String get remainingFormatted {
    final min = _remainingSeconds ~/ 60;
    final sec = _remainingSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  /// Whether this is a multi-line (interchange) journey
  bool get isInterchangeJourney =>
      _selectedRoute != null && _selectedRoute!.segments.length > 1;

  /// Label for the current active leg
  String get currentLegLabel {
    if (_selectedRoute == null) return '';
    if (_phase == AlarmPhase.leg1Active) {
      if (isInterchangeJourney) {
        final seg = _selectedRoute!.segments.first;
        return '${seg.stations.first.name} → ${seg.stations.last.name}';
      } else {
        return '${_sourceStation?.name} → ${_destStation?.name}';
      }
    } else if (_phase == AlarmPhase.leg2Active) {
      final seg = _selectedRoute!.segments.last;
      return '${seg.stations.first.name} → ${seg.stations.last.name}';
    }
    return '';
  }

  /// Current leg line name
  String get currentLegLineName {
    if (_selectedRoute == null) return '';
    if (_phase == AlarmPhase.leg1Active) {
      return _selectedRoute!.segments.first.lineName;
    } else if (_phase == AlarmPhase.leg2Active) {
      return _selectedRoute!.segments.last.lineName;
    }
    return '';
  }

  /// Current leg line color
  Color get currentLegLineColor {
    if (_selectedRoute == null) return Colors.grey;
    if (_phase == AlarmPhase.leg1Active) {
      return _selectedRoute!.segments.first.lineColor;
    } else if (_phase == AlarmPhase.leg2Active) {
      return _selectedRoute!.segments.last.lineColor;
    }
    return Colors.grey;
  }

  // ─── Actions ───

  /// Resolve route and start the alarm.
  /// Returns false if the journey is too short (≤ 5 min); true if the alarm was set.
  bool setAlarm(Station source, Station destination) {
    // Find the best route
    final routes = _metroData.findRoutes(source, destination);
    if (routes.isEmpty) {
      debugPrint('TransitAlarm: No route found');
      return false;
    }

    _sourceStation = source;
    _destStation = destination;
    _selectedRoute = routes.first;

    if (_selectedRoute!.segments.length == 1) {
      // ─── DIRECT journey ───
      final stops = _selectedRoute!.segments.first.stops;
      final totalMin = _metroData.estimateTravelTime(stops, 0);

      // Guard: journey too short for a meaningful alarm
      if (totalMin <= 5) {
        debugPrint('TransitAlarm: Journey too short ($totalMin min). Alarm not set.');
        _resetState();
        return false;
      }

      // Schedule alarm to fire 5 minutes before arrival
      final timerMin = totalMin - 5;
      _leg1TotalSeconds = timerMin * 60;
      _leg2TotalSeconds = 0;
      _interchangeStation = null;
      _nextLineName = null;

      NotificationService().scheduleDestinationAlarm(totalMin, destination.name);

      _startLegTimer(_leg1TotalSeconds, _onLeg1Complete);
      _phase = AlarmPhase.leg1Active;
    } else {
      // ─── INTERCHANGE journey ───
      final seg1 = _selectedRoute!.segments.first;
      final seg2 = _selectedRoute!.segments.last;

      final leg1Min = _metroData.estimateTravelTime(seg1.stops, 0);
      final leg2Min = _metroData.estimateTravelTime(seg2.stops, 0);

      // Guard: at least one leg must be longer than 5 minutes
      if (leg1Min <= 5 && leg2Min <= 5) {
        debugPrint('TransitAlarm: Journey too short. Alarm not set.');
        _resetState();
        return false;
      }

      // Apply 5-min buffer per leg (fire 5 min before each alert)
      final timer1Min = leg1Min > 5 ? leg1Min - 5 : 0;
      final timer2Min = leg2Min > 5 ? leg2Min - 5 : 0;

      _leg1TotalSeconds = timer1Min * 60;
      _leg2TotalSeconds = timer2Min * 60;

      // The interchange station is the last station of segment 1
      _interchangeStation = seg1.stations.last;
      _nextLineName = seg2.lineName;

      if (leg1Min > 5) {
        NotificationService().scheduleInterchangeAlarm(leg1Min, _interchangeStation!.name, _nextLineName!);
      }

      _startLegTimer(_leg1TotalSeconds, _onLeg1Complete);
      _phase = AlarmPhase.leg1Active;
    }

    debugPrint('TransitAlarm: Alarm set — ${_selectedRoute!.segments.length} segment(s)');
    notifyListeners();
    return true;
  }

  /// User confirms interchange boarding
  void confirmInterchangeBoarded() {
    if (_phase != AlarmPhase.awaitingInterchangeConfirm) return;

    if (_leg2TotalSeconds > 0) {
      final totalMin = (_leg2TotalSeconds ~/ 60) + 5;
      NotificationService().scheduleDestinationAlarm(totalMin, _destStation!.name);
    }

    _startLegTimer(_leg2TotalSeconds, _onLeg2Complete);
    _phase = AlarmPhase.leg2Active;
    notifyListeners();
  }

  /// Cancel the active alarm and reset everything
  void cancelAlarm() {
    _killTimers();
    _resetState();
    notifyListeners();
  }

  // ─── Internal timer logic ───

  void _startLegTimer(int totalSeconds, VoidCallback onComplete) {
    _killTimers();

    _remainingSeconds = totalSeconds;
    _currentLegTotalSeconds = totalSeconds;

    if (totalSeconds <= 0) {
      // Fire immediately
      onComplete();
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      notifyListeners();

      if (_remainingSeconds <= 0) {
        timer.cancel();
        onComplete();
      }
    });
  }

  void _onLeg1Complete() {
    _countdownTimer?.cancel();

    if (isInterchangeJourney) {
      // Fire interchange notification
      NotificationService().showInterchangeAlert(
        _interchangeStation?.name ?? 'Interchange',
        _nextLineName ?? 'next line',
      );
      _phase = AlarmPhase.awaitingInterchangeConfirm;
    } else {
      // Fire final destination notification
      NotificationService().showDestinationAlert(
        _destStation?.name ?? 'Destination',
      );
      _phase = AlarmPhase.completed;
      _scheduleAutoReset();
    }

    notifyListeners();
  }

  void _onLeg2Complete() {
    _countdownTimer?.cancel();

    // Fire final destination notification
    NotificationService().showDestinationAlert(
      _destStation?.name ?? 'Destination',
    );

    _phase = AlarmPhase.completed;
    notifyListeners();
    _scheduleAutoReset();
  }

  void _scheduleAutoReset() {
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(const Duration(seconds: 60), () {
      _resetState();
      notifyListeners();
    });
  }

  void _killTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _autoResetTimer?.cancel();
    _autoResetTimer = null;
  }

  void _resetState() {
    _killTimers();
    _phase = AlarmPhase.idle;
    _sourceStation = null;
    _destStation = null;
    _selectedRoute = null;
    _interchangeStation = null;
    _nextLineName = null;
    _leg1TotalSeconds = 0;
    _leg2TotalSeconds = 0;
    _remainingSeconds = 0;
    _currentLegTotalSeconds = 0;

    // Cancel any pending notifications
    NotificationService().cancelTransitAlarms();
  }

  @override
  void dispose() {
    _killTimers();
    super.dispose();
  }
}
