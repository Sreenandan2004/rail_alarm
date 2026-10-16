import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../models/alarm_info.dart';
import '../models/station.dart';
import '../services/isar_service.dart';
import '../services/station_service.dart';
import 'alarm_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<AlarmInfo> _alarms = [];
  List<Station> _suggestions = [];

  final IsarService _isarService = IsarService();
  final StationService _stationService = StationService();

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<AlarmInfo>>? _alarmsSubscription;

  @override
  void initState() {
    super.initState();
    _initServices();
    _startTracking();
  }

  Future<void> _initServices() async {
    await _stationService.init();
    _alarmsSubscription = _isarService.watchAlarms().listen((alarms) {
      if (mounted) {
        setState(() {
          _alarms = alarms;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _alarmsSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      if (_suggestions.isNotEmpty) {
        setState(() {
          _suggestions = [];
        });
      }
      return;
    }
    final results = _stationService.search(query, limit: 5);
    setState(() {
      _suggestions = results;
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  void _startTracking() {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _checkAlarms(position);
    });
  }

  void _checkAlarms(Position currentPosition) {
    for (var alarm in _alarms) {
      if (!alarm.isActive) continue;

      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        alarm.latitude,
        alarm.longitude,
      );

      double distanceInKm = distanceInMeters / 1000;

      if (distanceInKm < 10) {
        _triggerAlarm(alarm);
      }
    }
  }

  void _setSystemAlarm(String message, int hour, int minute) {
    if (kIsWeb) return;
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.MESSAGE': message,
        'android.intent.extra.alarm.HOUR': hour,
        'android.intent.extra.alarm.MINUTES': minute,
        'android.intent.extra.alarm.SKIP_UI': true,
      },
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  }

  Future<void> _triggerAlarm(AlarmInfo alarm) async {
    final scheduledTime = DateTime.now().add(const Duration(minutes: 1));

    _setSystemAlarm(
      "Arriving at ${alarm.location}!",
      scheduledTime.hour,
      scheduledTime.minute,
    );

    await _isarService.toggleAlarmActive(alarm.id, false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Arriving at ${alarm.location}! Alarm scheduled for 1 minute from now."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _addStationAlarm(Station station) async {
    double? distanceInKm;
    try {
      final currentPos = await _determinePosition();
      final distMeters = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        station.latitude,
        station.longitude,
      );
      distanceInKm = distMeters / 1000;
    } catch (_) {}

    final newAlarm = AlarmInfo(
      id: '${station.code}_${DateTime.now().millisecondsSinceEpoch}',
      location: '${station.name} (${station.code})',
      latitude: station.latitude,
      longitude: station.longitude,
      isActive: true,
    );

    await _isarService.saveAlarm(newAlarm);

    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _suggestions = [];
    });

    if (mounted) {
      final distText = distanceInKm != null
          ? " You are ${distanceInKm.toStringAsFixed(1)} km away."
          : "";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Alarm set for ${station.displayName}!$distText"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addNewAlarm(String query) async {
    final name = query.trim();
    if (name.isEmpty) return;

    // Check if coordinates were entered (e.g. "12.9716, 77.5946")
    final coordRegex = RegExp(r'^\s*(-?\d+(\.\d+)?)\s*,\s*(-?\d+(\.\d+)?)\s*$');
    final coordMatch = coordRegex.firstMatch(name);
    if (coordMatch != null) {
      final lat = double.tryParse(coordMatch.group(1)!);
      final lng = double.tryParse(coordMatch.group(3)!);
      if (lat != null && lng != null) {
        double? distanceInKm;
        try {
          Position currentPosition = await _determinePosition();
          double distanceInMeters = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            lat,
            lng,
          );
          distanceInKm = distanceInMeters / 1000;
        } catch (_) {}

        final newAlarm = AlarmInfo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          location: "Location (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})",
          latitude: lat,
          longitude: lng,
          isActive: true,
        );

        await _isarService.saveAlarm(newAlarm);
        _searchController.clear();
        _searchFocusNode.unfocus();
        setState(() {
          _suggestions = [];
        });

        if (mounted) {
          final distText = distanceInKm != null
              ? " You are ${distanceInKm.toStringAsFixed(1)} km away."
              : "";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Alarm set!$distText"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    final offlineMatches = _stationService.search(name, limit: 1);
    if (offlineMatches.isNotEmpty) {
      await _addStationAlarm(offlineMatches.first);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Searching for '$name'..."),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black54,
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      List<Location> locations = await locationFromAddress(name);

      if (locations.isNotEmpty) {
        final searchedLocation = locations.first;
        double? distanceInKm;
        try {
          Position currentPosition = await _determinePosition();
          double distanceInMeters = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            searchedLocation.latitude,
            searchedLocation.longitude,
          );
          distanceInKm = distanceInMeters / 1000;
        } catch (_) {}

        final newAlarm = AlarmInfo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          location: name,
          latitude: searchedLocation.latitude,
          longitude: searchedLocation.longitude,
          isActive: true,
        );

        await _isarService.saveAlarm(newAlarm);

        _searchController.clear();
        _searchFocusNode.unfocus();
        setState(() {
          _suggestions = [];
        });

        if (!mounted) return;
        final distText = distanceInKm != null
            ? " You are ${distanceInKm.toStringAsFixed(1)} km away."
            : "";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Alarm set for $name!$distText"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not find '$name'. Try another place name or enter coordinates (lat, lng)."),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAlarm(String id) async {
    await _isarService.deleteAlarm(id);
  }

  Future<void> _toggleAlarm(String id, bool isActive) async {
    await _isarService.toggleAlarmActive(id, isActive);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: _selectedIndex == 0
              ? _buildSearchPage()
              : AlarmPage(
                  alarms: _alarms,
                  onDelete: _deleteAlarm,
                  onToggle: _toggleAlarm,
                ),
          bottomNavigationBar: _buildCustomBottomBar(),
        ),
      ],
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavButton(
                  icon: Icons.account_circle,
                  isSelected: _selectedIndex == 0,
                  onTap: () {
                    if (_selectedIndex != 0) {
                      setState(() => _selectedIndex = 0);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildNavButton(
                  icon: Icons.alarm,
                  isSelected: _selectedIndex == 1,
                  onTap: () {
                    if (_selectedIndex != 1) {
                      setState(() => _selectedIndex = 1);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.12),
        ),
        child: Icon(
          icon,
          size: 28,
          color: isSelected
              ? Colors.black
              : Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _buildSearchPage() {
    return SizedBox(
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Text(
                  "RailAlarm",
                  style: GoogleFonts.urbanist(
                    fontSize: 55,
                    fontWeight: FontWeight.w100,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(
                  color: Colors.white54,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                const SizedBox(height: 30),
                Image.asset(
                  'assets/images/bus_railway.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  onSubmitted: _addNewAlarm,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.2),
                    hintText: "Enter location",
                    hintStyle: GoogleFonts.urbanist(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.white70),
                                onPressed: () => _addNewAlarm(_searchController.text),
                              ),
                            ],
                          )
                        : IconButton(
                            icon: const Icon(Icons.search, color: Colors.white70),
                            onPressed: () => _addNewAlarm(_searchController.text),
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSuggestionsList(),
                ],
                const SizedBox(height: 30),
                Text(
                  "Type your Location.\nAlarm will ring 10 kms\nbefore the destination.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.victorMono(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _suggestions.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final station = _suggestions[index];
              return ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    station.code,
                    style: GoogleFonts.victorMono(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                title: Text(
                  station.name,
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.alarm_add,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                onTap: () => _addStationAlarm(station),
              );
            },
          ),
        ),
      ),
    );
  }
}
