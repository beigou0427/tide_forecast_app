import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/tide_model.dart';

class MetricGrid extends StatelessWidget {
  final Observation current;

  const MetricGrid({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final List<Widget> metrics = [];

    void addIfValid(String label, double? val, String unit, IconData icon, Color color) {
      if (val != null) {
        metrics.add(_buildMetricTile(label, "$val$unit", icon, color));
      }
    }

    // 依序檢查所有可能的海象數據
    addIfValid("波浪高度", current.waveHeight, " m", Icons.waves, Colors.indigo);
    addIfValid("海水溫度", current.seaTemperature, " ℃", Icons.thermostat, Colors.orange);
    addIfValid("觀測風速", current.windSpeed, " m/s", Icons.air, Colors.green);
    addIfValid("海流流速", current.currentSpeed, " m/s", Icons.explore_outlined, Colors.teal);
    addIfValid("風向角度", current.windDirection, "°", Icons.navigation_outlined, Colors.brown);
    addIfValid("大氣壓力", current.airPressure, " hPa", Icons.speed, Colors.purple);
    addIfValid("即時氣溫", current.airTemperature, " ℃", Icons.wb_sunny_outlined, Colors.amber);

    if (metrics.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text("該測站目前僅提供基礎潮位資訊", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: metrics,
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 18, child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                FittedBox(child: Text(value, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.bold))),
              ],
            ),
          )
        ],
      ),
    );
  }
}