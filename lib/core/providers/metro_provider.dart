import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/metro_data.dart';
import '../models/models.dart';

class MetroProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final MetroData _metroData = MetroData();

  Station? _sourceStation;
  Station? _destinationStation;
  List<MetroRoute> _routes = [];
  MetroRoute? _selectedRoute;
  bool _isSearching = false;
  List<Station> _searchResults = [];

  MetroProvider(this._prefs) {
    // constructor body
  }

  // Getters
  MetroData get metroData => _metroData;
  Station? get sourceStation => _sourceStation;
  Station? get destinationStation => _destinationStation;
  List<MetroRoute> get routes => _routes;
  MetroRoute? get selectedRoute => _selectedRoute;
  bool get isSearching => _isSearching;
  List<Station> get searchResults => _searchResults;
  List<MetroLine> get lines => _metroData.lines;
  List<String> get allStationNames => _metroData.allStationNames;

  void setSource(Station? station) {
    _sourceStation = station;
    _routes = [];
    _selectedRoute = null;
    notifyListeners();
  }

  void setDestination(Station? station) {
    _destinationStation = station;
    _routes = [];
    _selectedRoute = null;
    notifyListeners();
  }

  void swapStations() {
    final temp = _sourceStation;
    _sourceStation = _destinationStation;
    _destinationStation = temp;
    if (_sourceStation != null && _destinationStation != null) {
      findRoutes();
    } else {
      _routes = [];
      _selectedRoute = null;
      notifyListeners();
    }
  }

  void findRoutes() {
    if (_sourceStation == null || _destinationStation == null) return;

    _routes = _metroData.findRoutes(_sourceStation!, _destinationStation!);
    _selectedRoute = _routes.isNotEmpty ? _routes.first : null;



    notifyListeners();
  }

  void selectRoute(MetroRoute route) {
    _selectedRoute = route;
    notifyListeners();
  }

  List<Station> searchStations(String query) {
    _searchResults = _metroData.searchStations(query);
    return _searchResults;
  }

  void clearRoute() {
    _sourceStation = null;
    _destinationStation = null;
    _routes = [];
    _selectedRoute = null;
    notifyListeners();
  }

  /// Get next train ETA based on frequency and current time
  Map<String, dynamic> getNextTrainETA(String lineId) {
    final line = _metroData.getLine(lineId);
    if (line == null) {
      return {'minutes': 0, 'nextTrain': '--:--'};
    }

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    // Parse first and last train times
    final firstParts = line.firstTrain.split(':');
    final lastParts = line.lastTrain.split(':');
    final firstMinutes = int.parse(firstParts[0]) * 60 + int.parse(firstParts[1]);
    final lastMinutesRaw = int.parse(lastParts[0]) * 60 + int.parse(lastParts[1]);

    final lastMinutes = lastMinutesRaw < firstMinutes 
        ? lastMinutesRaw + 1440 
        : lastMinutesRaw;

    int effectiveNow = nowMinutes;
    if (effectiveNow < firstMinutes && (effectiveNow + 1440) <= lastMinutes) {
      effectiveNow += 1440;
    }

    if (effectiveNow < firstMinutes) {
      final wait = firstMinutes - effectiveNow;
      return {
        'minutes': wait,
        'nextTrain': line.firstTrain,
        'status': 'Service starts at ${line.firstTrain}',
      };
    }

    if (effectiveNow > lastMinutes) {
      return {
        'minutes': -1,
        'nextTrain': line.firstTrain,
        'status': 'Service ended. First train at ${line.firstTrain}',
      };
    }

    // Calculate minutes since last train
    final minutesSinceFirst = effectiveNow - firstMinutes;
    final minutesSinceLastTrain = minutesSinceFirst % line.frequencyMinutes;
    final minutesToNext = line.frequencyMinutes - minutesSinceLastTrain;

    final nextTrainMinutes = effectiveNow + minutesToNext;
    final nextHour = ((nextTrainMinutes ~/ 60) % 24).toString().padLeft(2, '0');
    final nextMin = (nextTrainMinutes % 60).toString().padLeft(2, '0');

    return {
      'minutes': minutesToNext,
      'nextTrain': '$nextHour:$nextMin',
      'status': 'Next train in $minutesToNext min',
    };
  }

  /// Get popular stations (updated for corrected station names)
  List<Station> get popularStations {
    final names = [
      'Andheri', 'Ghatkopar', 'Versova', 'CSMT',
      'BKC', 'Dadar', 'Churchgate', 'Worli',
    ];
    final stations = <Station>[];
    for (final name in names) {
      final found = _metroData.findStationsByName(name);
      if (found.isNotEmpty) stations.add(found.first);
    }
    return stations;
  }
}
