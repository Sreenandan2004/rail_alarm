import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alarm_info.dart';

class AlarmPage extends StatelessWidget {
  final List<AlarmInfo> alarms;
  final Function(String) onDelete;

  const AlarmPage({
    super.key, 
    required this.alarms, 
    required this.onDelete
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
              const SizedBox(height: 60),
              Text(
                "ALL ALARMS",
                style: GoogleFonts.victorMono(
                  fontSize: 24,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
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
            const SizedBox(height: 100), // Space for NavBar
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No active alarms.\nSearch a location to add one!",
        textAlign: TextAlign.center,
        style: GoogleFonts.urbanist(color: Colors.white, fontSize: 20),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, AlarmInfo alarm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: alarm.isActive ? Colors.white.withOpacity(0.15) : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  alarm.location,
                  style: GoogleFonts.urbanist(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    decoration: alarm.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    onDelete(alarm.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Alarm deleted"),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
