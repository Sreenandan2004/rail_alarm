import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:google_fonts/google_fonts.dart';

/// Service to handle OEM battery optimization exemptions (Doze Mode).
/// Ensures RailAlarm's adaptive GPS tracking and alarms are not killed by aggressive OS task managers.
class BatteryOptimizationService {
  static const String defaultPackageName = 'com.sreenandan.rail_alarm';

  /// Prompts Android OS to whitelist the app from battery optimizations.
  static Future<bool> requestIgnoreBatteryOptimizations({
    String packageName = defaultPackageName,
  }) async {
    if (kIsWeb) return false;
    try {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:$packageName',
      );
      await intent.launch();
      return true;
    } catch (_) {
      // Fallback to opening overall battery optimization settings
      return await openBatteryOptimizationSettings();
    }
  }

  /// Opens the system Battery Optimization settings page where apps are listed.
  static Future<bool> openBatteryOptimizationSettings() async {
    if (kIsWeb) return false;
    try {
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens App Info / Details settings for RailAlarm.
  static Future<bool> openAppSettings({
    String packageName = defaultPackageName,
  }) async {
    if (kIsWeb) return false;
    try {
      final intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:$packageName',
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// List of manufacturer-specific battery saver configuration instructions.
  static const List<Map<String, String>> oemTips = [
    {
      'oem': 'Xiaomi / POCO / Redmi',
      'step': 'Settings > Apps > Manage Apps > RailAlarm > Battery Saver > Select "No restrictions" & Enable "Autostart".',
    },
    {
      'oem': 'Samsung (One UI)',
      'step': 'Settings > Apps > RailAlarm > Battery > Set to "Unrestricted" (or Device Care > Never Sleeping Apps).',
    },
    {
      'oem': 'OnePlus / OPPO / Realme',
      'step': 'Settings > Battery > App Battery Management > RailAlarm > Allow "Background activity" & "Auto-launch".',
    },
    {
      'oem': 'Vivo / iQOO',
      'step': 'Settings > Battery > High background power consumption > Turn switch ON for RailAlarm.',
    },
    {
      'oem': 'Google Pixel / Stock Android',
      'step': 'Settings > Apps > RailAlarm > App battery usage > Set to "Unrestricted".',
    },
  ];

  /// Displays the brand-aligned glassmorphic Battery Optimization Guide dialog.
  static Future<void> showOptimizationGuide(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.black.withValues(alpha: 0.88),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 14),
                    Text(
                      "BATTERY RESILIENCE",
                      style: GoogleFonts.victorMono(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Prevent Android Doze Mode from killing background location checks while you sleep.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.victorMono(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: oemTips.map((tip) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tip['oem']!,
                                  style: GoogleFonts.urbanist(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tip['step']!,
                                  style: GoogleFonts.victorMono(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: () async {
                        await requestIgnoreBatteryOptimizations();
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "DISABLE OPTIMIZATION",
                          style: GoogleFonts.urbanist(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Text(
                          "GOT IT, DISMISS",
                          style: GoogleFonts.victorMono(
                            color: Colors.white60,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
