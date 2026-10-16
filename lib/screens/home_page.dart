import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../models/alarm_info.dart';
import 'alarm_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final List<AlarmInfo> _alarms = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
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

  void _triggerAlarm(AlarmInfo alarm) {
    final scheduledTime = DateTime.now().add(const Duration(minutes: 1));
    
    _setSystemAlarm(
      "Arriving at ${alarm.location}!",
      scheduledTime.hour,
      scheduledTime.minute,
    );

    setState(() {
      int index = _alarms.indexWhere((a) => a.id == alarm.id);
      if (index != -1) {
         _alarms[index] = AlarmInfo(
           id: alarm.id,
           location: alarm.location,
           latitude: alarm.latitude,
           longitude: alarm.longitude,
           isActive: false, 
         );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ System Alarm set for 1 minute from now!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _addNewAlarm(String locationName) async {
    final name = locationName.trim();
    if (name.isEmpty) return;

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
        Position currentPosition = await _determinePosition();
        
        double distanceInMeters = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          searchedLocation.latitude,
          searchedLocation.longitude,
        );
        
        double distanceInKm = distanceInMeters / 1000;

        if (!mounted) return;
        setState(() {
          _alarms.add(
            AlarmInfo(
              id: DateTime.now().toString(),
              location: name,
              latitude: searchedLocation.latitude,
              longitude: searchedLocation.longitude,
              isActive: true,
            ),
          );
        });

        _searchController.clear();
        FocusScope.of(context).unfocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Alarm set! You are ${distanceInKm.toStringAsFixed(1)} km away."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not find '$name'. Check spelling or internet."),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteAlarm(String id) {
    setState(() {
      _alarms.removeWhere((alarm) => alarm.id == id);
    });
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
                ),
          bottomNavigationBar: Container(
            height: 120,
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 20),
            child: CrystalNavigationBar(
              currentIndex: _selectedIndex,
              paddingR: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              marginR: const EdgeInsets.symmetric(horizontal: 40),
              backgroundColor: Colors.black.withValues(alpha: 0.8),
              unselectedItemColor: Colors.white,
              outlineBorderColor: Colors.white.withValues(alpha: 0.2),
              
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              
              items: [
                CrystalNavigationBarItem(
                  icon: Icons.home_filled,
                  unselectedIcon: Icons.home_outlined,
                  selectedColor: Colors.white,
                ),
                CrystalNavigationBarItem(
                  icon: Icons.alarm,
                  unselectedIcon: Icons.alarm_off,
                  selectedColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPage() {
    return SizedBox(
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "RailAlarm",
                  style: GoogleFonts.urbanist(
                    fontSize: 55,
                    fontWeight: FontWeight.w100,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(
                  color: Colors.white54,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                const SizedBox(height: 40),
                const Icon(
                  Icons.train_outlined,
                  size: 120,
                  color: Colors.white,
                ),
                const SizedBox(height: 60),
                TextField(
                  controller: _searchController,
                  onSubmitted: _addNewAlarm,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.2),
                    hintText: "Enter location",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "Type your Location.\nAlarm will ring 10 kms\nbefore the destination.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.victorMono(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
