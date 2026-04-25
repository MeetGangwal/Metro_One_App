import 'package:flutter/material.dart';

class MetroLine {
  final String id;
  final String name;
  final String shortName;
  final Color color;
  final List<Station> stations;
  final String firstTrain;
  final String lastTrain;
  final int frequencyMinutes;

  const MetroLine({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.stations,
    required this.firstTrain,
    required this.lastTrain,
    required this.frequencyMinutes,
  });
}

class Station {
  final String id;
  final String name;
  final String lineId;
  final int index;
  final bool isInterchange;
  final List<String> connectedLineIds;
  final Map<String, String>? interchangeStationIds;

  final String? platformSide;
  final List<String>? gates;

  const Station({
    required this.id,
    required this.name,
    required this.lineId,
    required this.index,
    this.isInterchange = false,
    this.connectedLineIds = const [],
    this.interchangeStationIds,
    this.platformSide,
    this.gates,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Station && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

class MetroRoute {
  final Station source;
  final Station destination;
  final List<RouteSegment> segments;
  final int totalStops;
  final int estimatedMinutes;
  final double fare;
  final int interchanges;

  const MetroRoute({
    required this.source,
    required this.destination,
    required this.segments,
    required this.totalStops,
    required this.estimatedMinutes,
    required this.fare,
    required this.interchanges,
  });

  List<Station> get allStations {
    final stations = <Station>[];
    for (final segment in segments) {
      if (stations.isEmpty) {
        stations.addAll(segment.stations);
      } else {
        stations.addAll(segment.stations.skip(1));
      }
    }
    return stations;
  }

  /// Get a comma-separated string of line names taken in this route
  String get linesTaken => segments.map((s) => s.lineName).join(', ');
}

class RouteSegment {
  final String lineId;
  final String lineName;
  final Color lineColor;
  final List<Station> stations;
  final int stops;

  const RouteSegment({
    required this.lineId,
    required this.lineName,
    required this.lineColor,
    required this.stations,
    required this.stops,
  });
}

class MetroTicket {
  final String id;
  final String source;
  final String destination;
  final int stops;
  final double fare;
  final int estimatedMinutes;
  final DateTime createdAt;
  final String status;
  final String routeSummary;
  final String linesTaken;
  final String ticketType;

  const MetroTicket({
    required this.id,
    required this.source,
    required this.destination,
    required this.stops,
    required this.fare,
    required this.estimatedMinutes,
    required this.createdAt,
    this.status = 'active',
    required this.routeSummary,
    this.linesTaken = '',
    this.ticketType = 'single',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source': source,
      'destination': destination,
      'stops': stops,
      'fare': fare,
      'estimatedMinutes': estimatedMinutes,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'routeSummary': routeSummary,
      'linesTaken': linesTaken,
      'ticketType': ticketType,
    };
  }

  factory MetroTicket.fromMap(Map<String, dynamic> map) {
    return MetroTicket(
      id: map['id'],
      source: map['source'],
      destination: map['destination'],
      stops: map['stops'],
      fare: (map['fare'] as num).toDouble(),
      estimatedMinutes: map['estimatedMinutes'],
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? 'active',
      routeSummary: map['routeSummary'] ?? '',
      linesTaken: map['linesTaken'] ?? '',
      ticketType: map['ticketType'] ?? 'single',
    );
  }
}

enum CrowdLevel { low, medium, high, unknown }

class CrowdReport {
  final String stationId;
  final CrowdLevel level;
  final DateTime reportedAt;
  final String? userId;

  const CrowdReport({
    required this.stationId,
    required this.level,
    required this.reportedAt,
    this.userId,
  });
}

class SavedRoute {
  final String source;
  final String destination;
  final DateTime savedAt;

  const SavedRoute({
    required this.source,
    required this.destination,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'destination': destination,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SavedRoute.fromMap(Map<String, dynamic> map) {
    return SavedRoute(
      source: map['source'],
      destination: map['destination'],
      savedAt: DateTime.parse(map['savedAt']),
    );
  }
}
