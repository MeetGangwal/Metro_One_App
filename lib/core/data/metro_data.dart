import 'package:flutter/material.dart';
import '../models/models.dart';

/// Complete Mumbai Metro data with all 4 operational lines
/// Data corrected to match official Mumbai Metro route map
class MetroData {
  static final MetroData _instance = MetroData._internal();
  factory MetroData() => _instance;
  MetroData._internal();

  // ==================== LINE DEFINITIONS ====================

  late final List<MetroLine> lines = [blueLine, yellowLine, redLine, aquaLine];

  // ==================== BLUE LINE (Line 1) ====================
  // Versova ↔ Ghatkopar
  final MetroLine blueLine = MetroLine(
    id: 'blue',
    name: 'Blue Line',
    shortName: 'Line 1',
    color: const Color(0xFF0066CC),
    firstTrain: '05:00',
    lastTrain: '23:50',
    frequencyMinutes: 4,
    stations: const [
      Station(
        id: 'blue_versova',
        name: 'Versova',
        lineId: 'blue',
        index: 0,
      ),
      Station(
        id: 'blue_dn_nagar',
        name: 'D.N. Nagar',
        lineId: 'blue',
        index: 1,
        isInterchange: true,
        connectedLineIds: ['yellow'],
        interchangeStationIds: {'yellow': 'yellow_dn_nagar'},
        platformSide: 'Right',
        gates: ['Gate 1: Yellow Line Interchange', 'Gate 2: Bhavan\'s College'],
      ),
      Station(
        id: 'blue_azad_nagar',
        name: 'Azad Nagar',
        lineId: 'blue',
        index: 2,
      ),
      Station(
        id: 'blue_andheri',
        name: 'Andheri',
        lineId: 'blue',
        index: 3,
        // Interchange with Western Railway (non-metro, informational)
      ),
      Station(
        id: 'blue_weh',
        name: 'WEH',
        lineId: 'blue',
        index: 4,
        isInterchange: true,
        connectedLineIds: ['red'],
        interchangeStationIds: {'red': 'red_gundavali'},
        platformSide: 'Left',
        gates: ['Gate 1: Gundavali Interchange', 'Gate 3: P&G Plaza'],
      ),
      Station(
        id: 'blue_chakala',
        name: 'Chakala',
        lineId: 'blue',
        index: 5,
      ),
      Station(
        id: 'blue_airport_rd',
        name: 'Airport Rd',
        lineId: 'blue',
        index: 6,
      ),
      Station(
        id: 'blue_marol_naka',
        name: 'Marol Naka',
        lineId: 'blue',
        index: 7,
        isInterchange: true,
        connectedLineIds: ['aqua'],
        interchangeStationIds: {'aqua': 'aqua_marol_naka'},
      ),
      Station(
        id: 'blue_saki_naka',
        name: 'Saki Naka',
        lineId: 'blue',
        index: 8,
      ),
      Station(
        id: 'blue_asalpha',
        name: 'Asalpha',
        lineId: 'blue',
        index: 9,
      ),
      Station(
        id: 'blue_jagruti_nagar',
        name: 'Jagruti Nagar',
        lineId: 'blue',
        index: 10,
      ),
      Station(
        id: 'blue_ghatkopar',
        name: 'Ghatkopar',
        lineId: 'blue',
        index: 11,
      ),
    ],
  );

  // ==================== YELLOW LINE (Line 2A) ====================
  // Dahisar East ↔ Andheri West/D.N. Nagar
  final MetroLine yellowLine = MetroLine(
    id: 'yellow',
    name: 'Yellow Line',
    shortName: 'Line 2A',
    color: const Color(0xFFFFD700),
    firstTrain: '05:30',
    lastTrain: '23:30',
    frequencyMinutes: 5,
    stations: const [
      Station(
        id: 'yellow_dahisar_e',
        name: 'Dahisar East',
        lineId: 'yellow',
        index: 0,
        isInterchange: true,
        connectedLineIds: ['red'],
        interchangeStationIds: {'red': 'red_dahisar_e'},
      ),
      Station(
        id: 'yellow_anand_nagar',
        name: 'Anand Nagar',
        lineId: 'yellow',
        index: 1,
      ),
      Station(
        id: 'yellow_kandarpada',
        name: 'Kandarpada',
        lineId: 'yellow',
        index: 2,
      ),
      Station(
        id: 'yellow_mandapeshwar',
        name: 'Mandapeshwar',
        lineId: 'yellow',
        index: 3,
      ),
      Station(
        id: 'yellow_eksar',
        name: 'Eksar',
        lineId: 'yellow',
        index: 4,
      ),
      Station(
        id: 'yellow_borivali_w',
        name: 'Borivali West',
        lineId: 'yellow',
        index: 5,
      ),
      Station(
        id: 'yellow_pahadi_eksar',
        name: 'Pahadi Eksar',
        lineId: 'yellow',
        index: 6,
      ),
      Station(
        id: 'yellow_kandivali_w',
        name: 'Kandivali West',
        lineId: 'yellow',
        index: 7,
      ),
      Station(
        id: 'yellow_dahanukarwadi',
        name: 'Dahanukarwadi',
        lineId: 'yellow',
        index: 8,
      ),
      Station(
        id: 'yellow_valnai',
        name: 'Valnai',
        lineId: 'yellow',
        index: 9,
      ),
      Station(
        id: 'yellow_malad_w',
        name: 'Malad West',
        lineId: 'yellow',
        index: 10,
      ),
      Station(
        id: 'yellow_lower_malad',
        name: 'Lower Malad',
        lineId: 'yellow',
        index: 11,
      ),
      Station(
        id: 'yellow_pahadi_goregaon',
        name: 'Pahadi Goregaon',
        lineId: 'yellow',
        index: 12,
      ),
      Station(
        id: 'yellow_goregaon_w',
        name: 'Goregaon West',
        lineId: 'yellow',
        index: 13,
      ),
      Station(
        id: 'yellow_oshiwara',
        name: 'Oshiwara',
        lineId: 'yellow',
        index: 14,
      ),
      Station(
        id: 'yellow_lower_oshiwara',
        name: 'Lower Oshiwara',
        lineId: 'yellow',
        index: 15,
      ),
      Station(
        id: 'yellow_dn_nagar',
        name: 'Andheri West/D.N. Nagar',
        lineId: 'yellow',
        index: 16,
        isInterchange: true,
        connectedLineIds: ['blue'],
        interchangeStationIds: {'blue': 'blue_dn_nagar'},
        platformSide: 'Left',
        gates: ['Gate 2: Blue Line Interchange', 'Gate 3: Link Road', 'Gate 4: Andheri Sports Complex'],
      ),
    ],
  );

  // ==================== RED LINE (Line 7) ====================
  // Gundavali ↔ Dahisar East
  final MetroLine redLine = MetroLine(
    id: 'red',
    name: 'Red Line',
    shortName: 'Line 7',
    color: const Color(0xFFFF3333),
    firstTrain: '05:30',
    lastTrain: '23:30',
    frequencyMinutes: 5,
    stations: const [
      Station(
        id: 'red_gundavali',
        name: 'Gundavali',
        lineId: 'red',
        index: 0,
        isInterchange: true,
        connectedLineIds: ['blue'],
        interchangeStationIds: {'blue': 'blue_weh'},
        platformSide: 'Right',
        gates: ['Gate 1: WEH Interchange', 'Gate 2: Andheri East Station', 'Gate 4: MIDC'],
      ),
      Station(
        id: 'red_mogra',
        name: 'Mogra',
        lineId: 'red',
        index: 1,
      ),
      Station(
        id: 'red_jogeshwari_e',
        name: 'Jogeshwari East',
        lineId: 'red',
        index: 2,
      ),
      Station(
        id: 'red_goregaon_e',
        name: 'Goregaon East',
        lineId: 'red',
        index: 3,
      ),
      Station(
        id: 'red_aarey',
        name: 'Aarey',
        lineId: 'red',
        index: 4,
      ),
      Station(
        id: 'red_dindoshi',
        name: 'Dindoshi',
        lineId: 'red',
        index: 5,
      ),
      Station(
        id: 'red_kurar',
        name: 'Kurar',
        lineId: 'red',
        index: 6,
      ),
      Station(
        id: 'red_akurli',
        name: 'Akurli',
        lineId: 'red',
        index: 7,
      ),
      Station(
        id: 'red_poisar',
        name: 'Poisar',
        lineId: 'red',
        index: 8,
      ),
      Station(
        id: 'red_magathane',
        name: 'Magathane',
        lineId: 'red',
        index: 9,
      ),
      Station(
        id: 'red_devipada',
        name: 'Devipada',
        lineId: 'red',
        index: 10,
      ),
      Station(
        id: 'red_rashtriya_udyan',
        name: 'Rashtriya Udyan',
        lineId: 'red',
        index: 11,
      ),
      Station(
        id: 'red_ovaripada',
        name: 'Ovaripada',
        lineId: 'red',
        index: 12,
      ),
      Station(
        id: 'red_dahisar_e',
        name: 'Dahisar East',
        lineId: 'red',
        index: 13,
        isInterchange: true,
        connectedLineIds: ['yellow'],
        interchangeStationIds: {'yellow': 'yellow_dahisar_e'},
      ),
    ],
  );

  // ==================== AQUA LINE (Line 3) ====================
  // Cuffe Parade ↔ Aarey JVLR
  final MetroLine aquaLine = MetroLine(
    id: 'aqua',
    name: 'Aqua Line',
    shortName: 'Line 3',
    color: const Color(0xFF00BCD4),
    firstTrain: '05:15',
    lastTrain: '23:45',
    frequencyMinutes: 4,
    stations: const [
      Station(
        id: 'aqua_cuffe_parade',
        name: 'Cuffe Parade',
        lineId: 'aqua',
        index: 0,
      ),
      Station(
        id: 'aqua_vidhan_bhavan',
        name: 'Vidhan Bhavan',
        lineId: 'aqua',
        index: 1,
      ),
      Station(
        id: 'aqua_churchgate',
        name: 'Churchgate',
        lineId: 'aqua',
        index: 2,
      ),
      Station(
        id: 'aqua_hutatma_chowk',
        name: 'Hutatma Chowk',
        lineId: 'aqua',
        index: 3,
      ),
      Station(
        id: 'aqua_csmt',
        name: 'CSMT',
        lineId: 'aqua',
        index: 4,
      ),
      Station(
        id: 'aqua_grant_road',
        name: 'Grant Road',
        lineId: 'aqua',
        index: 5,
      ),
      Station(
        id: 'aqua_mumbai_central',
        name: 'Mumbai Central',
        lineId: 'aqua',
        index: 6,
      ),
      Station(
        id: 'aqua_mahalaxmi',
        name: 'Mahalaxmi',
        lineId: 'aqua',
        index: 7,
      ),
      Station(
        id: 'aqua_science_museum',
        name: 'Science Museum',
        lineId: 'aqua',
        index: 8,
      ),
      Station(
        id: 'aqua_acharya_atre',
        name: 'Acharya Atre Chowk',
        lineId: 'aqua',
        index: 9,
      ),
      Station(
        id: 'aqua_worli',
        name: 'Worli',
        lineId: 'aqua',
        index: 10,
      ),
      Station(
        id: 'aqua_siddhivinayak',
        name: 'Siddhivinayak',
        lineId: 'aqua',
        index: 11,
      ),
      Station(
        id: 'aqua_dadar',
        name: 'Dadar',
        lineId: 'aqua',
        index: 12,
      ),
      Station(
        id: 'aqua_sitaladevi',
        name: 'Sitaladevi',
        lineId: 'aqua',
        index: 13,
      ),
      Station(
        id: 'aqua_dharavi',
        name: 'Dharavi',
        lineId: 'aqua',
        index: 14,
      ),
      Station(
        id: 'aqua_bkc',
        name: 'BKC',
        lineId: 'aqua',
        index: 15,
      ),
      Station(
        id: 'aqua_vidyanagari',
        name: 'Vidyanagari',
        lineId: 'aqua',
        index: 16,
      ),
      Station(
        id: 'aqua_santacruz',
        name: 'Santacruz',
        lineId: 'aqua',
        index: 17,
      ),
      Station(
        id: 'aqua_csia_t1',
        name: 'CSIA T1',
        lineId: 'aqua',
        index: 18,
      ),
      Station(
        id: 'aqua_sahar_road',
        name: 'Sahar Road',
        lineId: 'aqua',
        index: 19,
      ),
      Station(
        id: 'aqua_csia_t2',
        name: 'CSIA T2',
        lineId: 'aqua',
        index: 20,
      ),
      Station(
        id: 'aqua_marol_naka',
        name: 'Marol Naka',
        lineId: 'aqua',
        index: 21,
        isInterchange: true,
        connectedLineIds: ['blue'],
        interchangeStationIds: {'blue': 'blue_marol_naka'},
      ),
      Station(
        id: 'aqua_midc_andheri',
        name: 'MIDC-Andheri',
        lineId: 'aqua',
        index: 22,
      ),
      Station(
        id: 'aqua_seepz',
        name: 'SEEPZ',
        lineId: 'aqua',
        index: 23,
      ),
      Station(
        id: 'aqua_aarey_jvlr',
        name: 'Aarey JVLR',
        lineId: 'aqua',
        index: 24,
      ),
    ],
  );

  // ==================== HELPER METHODS ====================

  /// Get all stations across all lines (deduplicated by name for search)
  List<Station> get allStations {
    final stations = <Station>[];
    for (final line in lines) {
      stations.addAll(line.stations);
    }
    return stations;
  }

  /// Get unique station names for search
  List<String> get allStationNames {
    final names = <String>{};
    for (final line in lines) {
      for (final station in line.stations) {
        names.add(station.name);
      }
    }
    return names.toList()..sort();
  }

  /// Find station by ID
  Station? findStationById(String id) {
    for (final line in lines) {
      for (final station in line.stations) {
        if (station.id == id) return station;
      }
    }
    return null;
  }

  /// Find stations by name (may return multiple if interchange)
  List<Station> findStationsByName(String name) {
    final results = <Station>[];
    for (final line in lines) {
      for (final station in line.stations) {
        if (station.name.toLowerCase() == name.toLowerCase()) {
          results.add(station);
        }
      }
    }
    return results;
  }

  /// Search stations by query
  List<Station> searchStations(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    final results = <String, Station>{};
    for (final line in lines) {
      for (final station in line.stations) {
        if (station.name.toLowerCase().contains(lowerQuery)) {
          results.putIfAbsent(station.name, () => station);
        }
      }
    }
    return results.values.toList();
  }

  /// Get line by ID
  MetroLine? getLine(String lineId) {
    for (final line in lines) {
      if (line.id == lineId) return line;
    }
    return null;
  }

  /// Get line color
  Color getLineColor(String lineId) {
    return getLine(lineId)?.color ?? Colors.grey;
  }

  /// Calculate fare based on number of stops
  double calculateFare(int stops) {
    if (stops <= 0) return 0;
    if (stops <= 2) return 10;
    if (stops <= 5) return 20;
    if (stops <= 8) return 30;
    if (stops <= 11) return 40;
    if (stops <= 14) return 50;
    if (stops <= 17) return 60;
    return 70;
  }

  /// Estimate travel time (2.5 min per stop + 5 min per interchange)
  int estimateTravelTime(int stops, int interchanges) {
    return (stops * 2.5).ceil() + (interchanges * 5);
  }

  // ==================== ROUTE FINDING ====================

  /// Find routes between source and destination
  List<MetroRoute> findRoutes(Station source, Station destination) {
    final routes = <MetroRoute>[];

    // Block ZERO-fare ghost routes between identical physical interchanges
    if (source.id == destination.id || 
        (source.interchangeStationIds != null && source.interchangeStationIds!.containsValue(destination.id))) {
      return routes;
    }

    // Check same line first (direct route)
    if (source.lineId == destination.lineId) {
      final route = _buildDirectRoute(source, destination);
      if (route != null) {
        routes.add(route);
        return routes; // Return immediately to avoid calculating redundant interchange loops
      }
    }

    // Check single interchange routes
    final interchangeRoutes = _findInterchangeRoutes(source, destination);
    routes.addAll(interchangeRoutes);

    // DEDUPLICATION: Remove routes with identical segment paths
    final seen = <String>{};
    final deduped = <MetroRoute>[];
    for (final route in routes) {
      // Generate a unique key from segments: lineId + station IDs
      final key = route.segments
          .map((s) => '${s.lineId}:${s.stations.map((st) => st.id).join(",")}')
          .join('|');
      if (!seen.contains(key)) {
        seen.add(key);
        deduped.add(route);
      }
    }

    // Sort by travel time
    deduped.sort((a, b) => a.estimatedMinutes.compareTo(b.estimatedMinutes));

    return deduped.isEmpty ? deduped : deduped.take(3).toList();
  }

  MetroRoute? _buildDirectRoute(Station source, Station destination) {
    final line = getLine(source.lineId);
    if (line == null) return null;

    final startIdx = source.index;
    final endIdx = destination.index;
    final stations = startIdx <= endIdx
        ? line.stations.sublist(startIdx, endIdx + 1)
        : line.stations.sublist(endIdx, startIdx + 1).reversed.toList();

    final stops = (endIdx - startIdx).abs();
    final fare = calculateFare(stops);
    final time = estimateTravelTime(stops, 0);

    return MetroRoute(
      source: source,
      destination: destination,
      segments: [
        RouteSegment(
          lineId: line.id,
          lineName: line.name,
          lineColor: line.color,
          stations: stations,
          stops: stops,
        ),
      ],
      totalStops: stops,
      estimatedMinutes: time,
      fare: fare,
      interchanges: 0,
    );
  }

  List<MetroRoute> _findInterchangeRoutes(Station source, Station destination) {
    final routes = <MetroRoute>[];
    final sourceLine = getLine(source.lineId);
    final destLine = getLine(destination.lineId);
    if (sourceLine == null || destLine == null) return routes;

    // Find interchange stations on source line
    for (final station in sourceLine.stations) {
      if (station.isInterchange && station.interchangeStationIds != null) {
        for (final entry in station.interchangeStationIds!.entries) {
          if (entry.key == destination.lineId) {
            // Direct interchange found
            final interchangeStation = findStationById(entry.value);
            if (interchangeStation != null) {
              final route = _buildTwoSegmentRoute(
                source, station, interchangeStation, destination,
              );
              if (route != null) routes.add(route);
            }
          } else {
            // Check if the connected line has a path to destination line
            final midStation = findStationById(entry.value);
            if (midStation != null) {
              final midLine = getLine(midStation.lineId);
              if (midLine != null) {
                for (final midInterchange in midLine.stations) {
                  if (midInterchange.isInterchange &&
                      midInterchange.interchangeStationIds != null &&
                      midInterchange.interchangeStationIds!.containsKey(destination.lineId)) {
                    final finalInterchange = findStationById(
                      midInterchange.interchangeStationIds![destination.lineId]!,
                    );
                    if (finalInterchange != null) {
                      final route = _buildThreeSegmentRoute(
                        source, station, midStation, midInterchange,
                        finalInterchange, destination,
                      );
                      if (route != null) routes.add(route);
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    return routes;
  }

  MetroRoute? _buildTwoSegmentRoute(
    Station source, Station interchange1, Station interchange2, Station destination,
  ) {
    final line1 = getLine(source.lineId);
    final line2 = getLine(destination.lineId);
    if (line1 == null || line2 == null) return null;

    final seg1Stations = _getStationsBetween(line1, source, interchange1);
    final seg2Stations = _getStationsBetween(line2, interchange2, destination);

    if (seg1Stations.isEmpty || seg2Stations.isEmpty) return null;

    final stops1 = seg1Stations.length - 1;
    final stops2 = seg2Stations.length - 1;
    final totalStops = stops1 + stops2;
    final fare = calculateFare(totalStops);
    final time = estimateTravelTime(totalStops, 1);

    return MetroRoute(
      source: source,
      destination: destination,
      segments: [
        RouteSegment(lineId: line1.id, lineName: line1.name, lineColor: line1.color,
          stations: seg1Stations, stops: stops1),
        RouteSegment(lineId: line2.id, lineName: line2.name, lineColor: line2.color,
          stations: seg2Stations, stops: stops2),
      ],
      totalStops: totalStops,
      estimatedMinutes: time,
      fare: fare,
      interchanges: 1,
    );
  }

  MetroRoute? _buildThreeSegmentRoute(
    Station source, Station int1a, Station int1b,
    Station int2a, Station int2b, Station destination,
  ) {
    final line1 = getLine(source.lineId);
    final line2 = getLine(int1b.lineId);
    final line3 = getLine(destination.lineId);
    if (line1 == null || line2 == null || line3 == null) return null;

    final seg1 = _getStationsBetween(line1, source, int1a);
    final seg2 = _getStationsBetween(line2, int1b, int2a);
    final seg3 = _getStationsBetween(line3, int2b, destination);

    if (seg1.isEmpty || seg2.isEmpty || seg3.isEmpty) return null;

    final totalStops = (seg1.length - 1) + (seg2.length - 1) + (seg3.length - 1);
    final fare = calculateFare(totalStops);
    final time = estimateTravelTime(totalStops, 2);

    return MetroRoute(
      source: source,
      destination: destination,
      segments: [
        RouteSegment(lineId: line1.id, lineName: line1.name, lineColor: line1.color,
          stations: seg1, stops: seg1.length - 1),
        RouteSegment(lineId: line2.id, lineName: line2.name, lineColor: line2.color,
          stations: seg2, stops: seg2.length - 1),
        RouteSegment(lineId: line3.id, lineName: line3.name, lineColor: line3.color,
          stations: seg3, stops: seg3.length - 1),
      ],
      totalStops: totalStops,
      estimatedMinutes: time,
      fare: fare,
      interchanges: 2,
    );
  }

  List<Station> _getStationsBetween(MetroLine line, Station from, Station to) {
    final startIdx = from.index;
    final endIdx = to.index;
    if (startIdx <= endIdx) {
      return line.stations.sublist(startIdx, endIdx + 1);
    } else {
      return line.stations.sublist(endIdx, startIdx + 1).reversed.toList();
    }
  }
}
