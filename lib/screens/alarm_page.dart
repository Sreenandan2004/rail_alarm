import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alarm_info.dart';
import '../models/tracking_state.dart';
import '../services/adaptive_location_service.dart';
import '../services/alarm_dispatch_service.dart';
import '../utils/geo_utils.dart';

class AlarmPage extends StatelessWidget {
  final List<AlarmInfo> alarms;
  final Function(String) onDelete;
  final Function(String, bool)? onToggle;
  final Function(String, double)? onUpdateLeadDistance;
  final Position? currentPosition;
  final AdaptiveTrackingDecision? lastDecision;

  const AlarmPage({
    super.key,
    required this.alarms,
    required this.onDelete,
    this.onToggle,
    this.onUpdateLeadDistance,
    this.currentPosition,
    this.lastDecision,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 20),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
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
            if (alarms.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                "ALL ALARMS",
                style: GoogleFonts.victorMono(
                  fontSize: 24,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: alarms.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: alarms.length,
                      itemBuilder: (context, index) {
                        return _buildGlassCard(context, alarms[index]);
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              "App Developed by\nSreenandan S",
              textAlign: TextAlign.center,
              style: GoogleFonts.victorMono(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 90), // Space for custom NavBar
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No active alarms.\nEnter a location to add one!",
        textAlign: TextAlign.center,
        style: GoogleFonts.urbanist(color: Colors.white70, fontSize: 18),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, AlarmInfo alarm) {
    double? distKm;
    if (currentPosition != null) {
      distKm = GeoUtils.haversineDistanceKm(
        currentPosition!.latitude,
        currentPosition!.longitude,
        alarm.latitude,
        alarm.longitude,
      );
    }

    String subtitleText;
    if (!alarm.isActive) {
      subtitleText = "Alarm Inactive / Paused";
    } else if (distKm != null) {
      final tier = AdaptiveLocationService.evaluateTier(
        distanceKm: distKm,
        leadDistanceKm: alarm.leadDistanceKm,
      );
      String tierTag;
      switch (tier) {
        case DistanceTier.far:
          tierTag = "Far (>50km • Low Power)";
          break;
        case DistanceTier.approaching:
          tierTag = "Approaching (Balanced)";
          break;
        case DistanceTier.near:
          tierTag = "Near (High GPS)";
          break;
        case DistanceTier.alarmRange:
          tierTag = "Alarm Trigger Boundary!";
          break;
      }
      subtitleText = "${distKm.toStringAsFixed(1)} km away • $tierTag";
    } else {
      subtitleText = "Tracking Active (<${alarm.leadDistanceKm.toStringAsFixed(0)} km)";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 92,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: alarm.isActive
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (onToggle != null) {
                        onToggle!(alarm.id, !alarm.isActive);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alarm.location,
                          style: GoogleFonts.urbanist(
                            fontSize: 19,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            decoration: alarm.isActive
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitleText,
                          style: GoogleFonts.victorMono(
                            fontSize: 11,
                            color: alarm.isActive ? Colors.greenAccent : Colors.white60,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Interactive lead-distance tag chip
                GestureDetector(
                  onTap: () {
                    if (onUpdateLeadDistance != null) {
                      // Cycle through 2km -> 5km -> 10km
                      double nextLead = 10.0;
                      if (alarm.leadDistanceKm >= 10.0) {
                        nextLead = 2.0;
                      } else if (alarm.leadDistanceKm <= 2.0) {
                        nextLead = 5.0;
                      }
                      onUpdateLeadDistance!(alarm.id, nextLead);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      "<${alarm.leadDistanceKm.toStringAsFixed(0)}km",
                      style: GoogleFonts.victorMono(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("🔔 Testing native alarm for '${alarm.location}'..."),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    await AlarmDispatchService.testSystemAlarm(locationName: alarm.location);
                  },
                  icon: const Icon(Icons.alarm_on, color: Colors.greenAccent),
                  tooltip: "Test Native Alarm",
                ),
                IconButton(
                  onPressed: () {
                    onDelete(alarm.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Alarm for '${alarm.location}' deleted"),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  tooltip: "Delete Alarm",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
