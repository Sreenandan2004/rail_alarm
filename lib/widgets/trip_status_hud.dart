import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alarm_info.dart';
import '../models/tracking_state.dart';
import '../utils/geo_utils.dart';

/// Glassmorphic Live Trip HUD displaying real-time tracking metrics,
/// Safe Sleep battery status, distance remaining, and next GPS polling interval.
class TripStatusHud extends StatelessWidget {
  final AlarmInfo? activeAlarm;
  final AdaptiveTrackingDecision? decision;
  final VoidCallback? onBatteryGuideTap;
  final VoidCallback? onViewAlarmsTap;

  const TripStatusHud({
    super.key,
    this.activeAlarm,
    this.decision,
    this.onBatteryGuideTap,
    this.onViewAlarmsTap,
  });

  @override
  Widget build(BuildContext context) {
    if (activeAlarm == null) {
      return _buildIdlePill(context);
    }

    return _buildActiveHud(context);
  }

  Widget _buildIdlePill(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "No active trip • Search below to set alarm",
                  style: GoogleFonts.victorMono(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
                if (onBatteryGuideTap != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onBatteryGuideTap,
                    child: Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveHud(BuildContext context) {
    final alarm = activeAlarm!;
    final dec = decision;
    final distText = dec != null ? "${dec.distanceKm.toStringAsFixed(1)} km" : "...";
    final speedText = dec != null ? "${dec.currentSpeedKmh.toStringAsFixed(0)} km/h" : "--";
    final etaText = dec?.eta != null ? GeoUtils.formatEta(dec!.eta!) : "--";

    String sleepText = "Evaluating GPS...";
    if (dec != null) {
      if (dec.sleepInterval.inSeconds >= 60) {
        final mins = (dec.sleepInterval.inSeconds / 60).toStringAsFixed(1);
        sleepText = "Next GPS check in $mins min";
      } else {
        sleepText = "Next GPS check in ${dec.sleepInterval.inSeconds}s";
      }
    }

    final tier = dec?.tier ?? DistanceTier.far;
    String tierName;
    switch (tier) {
      case DistanceTier.far:
        tierName = "FAR (>50KM)";
        break;
      case DistanceTier.approaching:
        tierName = "APPROACHING";
        break;
      case DistanceTier.near:
        tierName = "NEAR (<15KM)";
        break;
      case DistanceTier.alarmRange:
        tierName = "ARRIVING NOW";
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top header: Live badge + Tier + Battery shield button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "LIVE TRIP MONITOR",
                          style: GoogleFonts.victorMono(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tierName,
                            style: GoogleFonts.victorMono(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (onBatteryGuideTap != null)
                      GestureDetector(
                        onTap: onBatteryGuideTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 14, color: Colors.greenAccent),
                              const SizedBox(width: 4),
                              Text(
                                "Doze Shield",
                                style: GoogleFonts.victorMono(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Target Destination
                GestureDetector(
                  onTap: onViewAlarmsTap,
                  child: Text(
                    alarm.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.urbanist(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Telemetry cards: Remaining Distance, Current Speed, ETA
                Row(
                  children: [
                    _buildStatItem("DISTANCE", distText),
                    _buildStatItem("SPEED", speedText),
                    _buildStatItem("EST. ARRIVAL", etaText),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 8),
                // Footer: Safe sleep poll interval and ring threshold
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "⚡ $sleepText",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.victorMono(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      "Alarm @ <${alarm.leadDistanceKm.toStringAsFixed(0)}km",
                      style: GoogleFonts.victorMono(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.victorMono(
              color: Colors.white54,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.victorMono(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
