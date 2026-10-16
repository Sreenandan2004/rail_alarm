import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/alarm_info.dart';
import '../models/station.dart';
import '../models/tracking_state.dart';
import '../services/adaptive_location_service.dart';
import '../services/alarm_dispatch_service.dart';
import '../services/battery_optimization_service.dart';
import '../services/isar_service.dart';
import '../services/station_service.dart';
import '../widgets/trip_status_hud.dart';
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

  double _selectedLeadDistance = 10.0;
  bool _isAdding = false;
  Position? _currentPosition;
  AdaptiveTrackingDecision? _lastDecision;
  Timer? _adaptivePollTimer;

  final IsarService _isarService = IsarService();
  final StationService _stationService = StationService();

  StreamSubscription<List<AlarmInfo>>? _alarmsSubscription;

  @override
  void initState() {
    super.initState();
    _initServices();
    _startTracking();
  }

  Future<void> _initServices() async {
    await _stationService.init();
    try {
      final initialAlarms = await _isarService.getAllAlarms();
      if (mounted) {
        setState(() {
          _alarms = initialAlarms;
        });
        _runAdaptiveCheck();
      }
    } catch (_) {}

    _alarmsSubscription = _isarService.watchAlarms().listen((alarms) {
      if (mounted) {
        setState(() {
          _alarms = alarms;
        });
        _runAdaptiveCheck();
      }
    });
  }

  @override
  void dispose() {
    _adaptivePollTimer?.cancel();
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

  Future<Position?> _determinePosition({LocationAccuracy accuracy = LocationAccuracy.high}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  void _startTracking() {
    _runAdaptiveCheck();
  }

  /// Adaptive Distance-Tiered Polling loop that saves battery life
  Future<void> _runAdaptiveCheck() async {
    _adaptivePollTimer?.cancel();

    final activeAlarms = _alarms.where((a) => a.isActive).toList();
    if (activeAlarms.isEmpty) {
      if (mounted && _lastDecision != null) {
        setState(() {
          _lastDecision = null;
        });
      }
      return;
    }

    try {
      // Determine optimal hardware accuracy for current state
      final currentAccuracy = _lastDecision?.locationAccuracy ?? LocationAccuracy.high;
      final position = await _determinePosition(accuracy: currentAccuracy);

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });

      if (position == null) {
        // Retry in 15 seconds if position couldn't be obtained
        _adaptivePollTimer = Timer(const Duration(seconds: 15), _runAdaptiveCheck);
        return;
      }

      // 1. Evaluate all active alarms
      for (final alarm in activeAlarms) {
        final decision = AdaptiveLocationService.evaluate(
          currentPosition: position,
          alarm: alarm,
        );

        if (decision.shouldTrigger) {
          await _triggerAlarm(alarm);
        }
      }

      // 2. Compute safe sleep interval for the closest remaining active alarm
      final remainingActive = _alarms.where((a) => a.isActive).toList();
      if (remainingActive.isEmpty) {
        _adaptivePollTimer?.cancel();
        if (mounted) {
          setState(() {
            _lastDecision = null;
          });
        }
        return;
      }

      final closest = AdaptiveLocationService.findClosestActiveAlarm(
        currentPosition: position,
        alarms: remainingActive,
      );

      if (closest != null) {
        final decision = AdaptiveLocationService.evaluate(
          currentPosition: position,
          alarm: closest,
        );

        if (mounted) {
          setState(() {
            _lastDecision = decision;
          });
        }

        // Schedule next check dynamically using the Safe Sleep formula
        _adaptivePollTimer = Timer(decision.sleepInterval, _runAdaptiveCheck);
      }
    } catch (_) {
      // Temporary GPS dropout (e.g. tunnel), retry in 30 seconds
      _adaptivePollTimer = Timer(const Duration(seconds: 30), _runAdaptiveCheck);
    }
  }

  Future<void> _triggerAlarm(AlarmInfo alarm) async {
    // Immediately mark inactive locally to avoid duplicate trigger race conditions
    if (mounted) {
      setState(() {
        final idx = _alarms.indexWhere((a) => a.id == alarm.id);
        if (idx != -1) {
          _alarms[idx] = _alarms[idx].copyWith(isActive: false);
        }
      });
    }

    final success = await AlarmDispatchService.dispatchSystemAlarm(
      locationName: alarm.location,
    );

    await _isarService.toggleAlarmActive(alarm.id, false);

    if (mounted) {
      _showArrivalDialog(alarm, success);
    }
  }

  void _showArrivalDialog(AlarmInfo alarm, bool intentLaunched) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.black.withValues(alpha: 0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "RailAlarm",
                    style: GoogleFonts.urbanist(
                      fontSize: 34,
                      fontWeight: FontWeight.w100,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, thickness: 1),
                  const SizedBox(height: 20),
                  Text(
                    "YOU HAVE ARRIVED NEAR",
                    style: GoogleFonts.victorMono(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    alarm.location,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    intentLaunched
                        ? "Your phone's native alarm has been scheduled to wake you up!"
                        : "You are within ${alarm.leadDistanceKm.toStringAsFixed(0)} km of your destination.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.victorMono(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "DISMISS",
                        style: GoogleFonts.urbanist(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addStationAlarm(Station station) async {
    if (_isAdding) return;
    setState(() => _isAdding = true);

    try {
      double? distanceInKm;
      try {
        final currentPos = await _determinePosition();
        if (currentPos != null) {
          final distMeters = Geolocator.distanceBetween(
            currentPos.latitude,
            currentPos.longitude,
            station.latitude,
            station.longitude,
          );
          distanceInKm = distMeters / 1000;
        }
      } catch (_) {}

      final newAlarm = AlarmInfo(
        id: '${station.code}_${DateTime.now().millisecondsSinceEpoch}',
        location: '${station.name} (${station.code})',
        latitude: station.latitude,
        longitude: station.longitude,
        isActive: true,
        leadDistanceKm: _selectedLeadDistance,
      );

      await _isarService.saveAlarm(newAlarm);

      _searchController.clear();
      _searchFocusNode.unfocus();
      setState(() {
        _suggestions = [];
        _selectedIndex = 1; // Automatically navigate to the Alarms tab to view newly added alarm
      });

      if (mounted) {
        final distText = distanceInKm != null
            ? " (${distanceInKm.toStringAsFixed(1)} km away)"
            : "";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Alarm active for ${station.displayName}!$distText",
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: "VIEW",
              textColor: Colors.white,
              onPressed: () {
                if (mounted) setState(() => _selectedIndex = 1);
              },
            ),
          ),
        );
      }
      _runAdaptiveCheck();
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _addNewAlarm(String query) async {
    final name = query.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please type a station, city, or coordinates first."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_isAdding) return;
    setState(() => _isAdding = true);

    try {
      // 1. Check if coordinates were entered (e.g. "12.9716, 77.5946")
      final coordRegex = RegExp(r'^\s*(-?\d+(\.\d+)?)\s*,\s*(-?\d+(\.\d+)?)\s*$');
      final coordMatch = coordRegex.firstMatch(name);
      if (coordMatch != null) {
        final lat = double.tryParse(coordMatch.group(1)!);
        final lng = double.tryParse(coordMatch.group(3)!);
        if (lat != null && lng != null) {
          double? distanceInKm;
          try {
            Position? currentPosition = await _determinePosition();
            if (currentPosition != null) {
              double distanceInMeters = Geolocator.distanceBetween(
                currentPosition.latitude,
                currentPosition.longitude,
                lat,
                lng,
              );
              distanceInKm = distanceInMeters / 1000;
            }
          } catch (_) {}

          final newAlarm = AlarmInfo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            location: "Location (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})",
            latitude: lat,
            longitude: lng,
            isActive: true,
            leadDistanceKm: _selectedLeadDistance,
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
                content: Text(
                  "Alarm set! Ring at <${_selectedLeadDistance.toStringAsFixed(0)}km.$distText",
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _runAdaptiveCheck();
          return;
        }
      }

      // 2. Check offline database (instant, works with zero network)
      final offlineMatches = _stationService.search(name, limit: 1);
      if (offlineMatches.isNotEmpty) {
        await _addStationAlarm(offlineMatches.first);
        return;
      }

      // 3. Fallback to online geocoding
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Searching for '$name'..."),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.black54,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final locations = await locationFromAddress(name).timeout(
        const Duration(seconds: 6),
        onTimeout: () => [],
      );

      if (locations.isNotEmpty) {
        final searchedLocation = locations.first;
        double? distanceInKm;
        try {
          Position? currentPosition = await _determinePosition();
          if (currentPosition != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              currentPosition.latitude,
              currentPosition.longitude,
              searchedLocation.latitude,
              searchedLocation.longitude,
            );
            distanceInKm = distanceInMeters / 1000;
          }
        } catch (_) {}

        final newAlarm = AlarmInfo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          location: name,
          latitude: searchedLocation.latitude,
          longitude: searchedLocation.longitude,
          isActive: true,
          leadDistanceKm: _selectedLeadDistance,
        );

        await _isarService.saveAlarm(newAlarm);

        _searchController.clear();
        _searchFocusNode.unfocus();
        setState(() {
          _suggestions = [];
          _selectedIndex = 1;
        });

        if (mounted) {
          final distText = distanceInKm != null
              ? " (${distanceInKm.toStringAsFixed(1)} km away)"
              : "";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Alarm active for $name!$distText",
              ),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: "VIEW",
                textColor: Colors.white,
                onPressed: () {
                  if (mounted) setState(() => _selectedIndex = 1);
                },
              ),
            ),
          );
        }
        _runAdaptiveCheck();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Could not find '$name'. Try station code/name or coordinates."),
              backgroundColor: Colors.red.withValues(alpha: 0.8),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not find '$name'. Check internet or enter station code."),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteAlarm(String id) async {
    await _isarService.deleteAlarm(id);
    _runAdaptiveCheck();
  }

  Future<void> _toggleAlarm(String id, bool isActive) async {
    await _isarService.toggleAlarmActive(id, isActive);
    _runAdaptiveCheck();
  }

  Future<void> _updateAlarmLeadDistance(String id, double leadDistanceKm) async {
    await _isarService.updateAlarmLeadDistance(id, leadDistanceKm);
    _runAdaptiveCheck();
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
                  onUpdateLeadDistance: _updateAlarmLeadDistance,
                  currentPosition: _currentPosition,
                  lastDecision: _lastDecision,
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
                  icon: Icons.search,
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
    final activeAlarms = _alarms.where((a) => a.isActive).toList();
    AlarmInfo? closestActiveAlarm;
    if (activeAlarms.isNotEmpty) {
      if (_currentPosition != null) {
        closestActiveAlarm = AdaptiveLocationService.findClosestActiveAlarm(
          currentPosition: _currentPosition!,
          alarms: activeAlarms,
        );
      }
      closestActiveAlarm ??= activeAlarms.first;
    }

    return SizedBox(
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Text(
                  "RailAlarm",
                  style: GoogleFonts.urbanist(
                    fontSize: 55,
                    fontWeight: FontWeight.w100,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(
                  color: Colors.white54,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                const SizedBox(height: 12),
                TripStatusHud(
                  activeAlarm: closestActiveAlarm,
                  decision: _lastDecision,
                  onBatteryGuideTap: () => BatteryOptimizationService.showOptimizationGuide(context),
                  onViewAlarmsTap: () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(height: 12),
                Image.asset(
                  'assets/images/bus_railway.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 14),
                _buildLeadDistanceSelector(),
                const SizedBox(height: 18),
                _buildAddAlarmButton(),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSuggestionsList(),
                ],
                const SizedBox(height: 24),
                Text(
                  "Type your Location.\nAlarm will ring ${_selectedLeadDistance.toStringAsFixed(0)} kms\nbefore the destination.",
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

  Widget _buildLeadDistanceSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeChip(distance: 2.0, label: "2 km Bus/Car"),
        const SizedBox(width: 8),
        _buildModeChip(distance: 5.0, label: "5 km Road"),
        const SizedBox(width: 8),
        _buildModeChip(distance: 10.0, label: "10 km Train"),
      ],
    );
  }

  Widget _buildModeChip({required double distance, required String label}) {
    final isSelected = _selectedLeadDistance == distance;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLeadDistance = distance;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.victorMono(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildAddAlarmButton() {
    return GestureDetector(
      onTap: _isAdding ? null : () => _addNewAlarm(_searchController.text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isAdding
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_alarm, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "ADD ALARM",
                    style: GoogleFonts.urbanist(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
