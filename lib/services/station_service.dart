import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/station.dart';

class StationService {
  static final StationService _instance = StationService._internal();
  factory StationService() => _instance;
  StationService._internal();

  List<Station> _stations = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Station> get allStations => List.unmodifiable(_stations);

  /// Load stations from assets/data/stations.json
  Future<void> init([String assetPath = 'assets/data/stations.json']) async {
    if (_isLoaded && _stations.isNotEmpty) return;
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      _stations = jsonList.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
      _isLoaded = true;
    } catch (e) {
      _stations = [];
      _isLoaded = false;
    }
  }

  /// Direct injection for testing
  void setStationsForTesting(List<Station> stations) {
    _stations = List.from(stations);
    _isLoaded = true;
  }

  /// Fast offline search:
  /// 1. Exact station code match
  /// 2. Station code prefix match
  /// 3. Station name prefix match
  /// 4. Station name substring match
  List<Station> search(String query, {int limit = 10}) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final upperQuery = cleanQuery.toUpperCase();
    final lowerQuery = cleanQuery.toLowerCase();

    final List<Station> exactCodeMatches = [];
    final List<Station> prefixCodeMatches = [];
    final List<Station> prefixNameMatches = [];
    final List<Station> substringNameMatches = [];

    for (final station in _stations) {
      final stationCodeUpper = station.code.toUpperCase();
      final stationNameLower = station.name.toLowerCase();

      if (stationCodeUpper == upperQuery) {
        exactCodeMatches.add(station);
      } else if (stationCodeUpper.startsWith(upperQuery)) {
        prefixCodeMatches.add(station);
      } else if (stationNameLower.startsWith(lowerQuery)) {
        prefixNameMatches.add(station);
      } else if (stationNameLower.contains(lowerQuery)) {
        substringNameMatches.add(station);
      }
    }

    final combined = <Station>[
      ...exactCodeMatches,
      ...prefixCodeMatches,
      ...prefixNameMatches,
      ...substringNameMatches,
    ];

    final unique = <String, Station>{};
    for (final s in combined) {
      unique.putIfAbsent(s.code, () => s);
      if (unique.length >= limit) break;
    }

    return unique.values.toList();
  }
}
