import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../data/tide_model.dart';

class HeroMetricCard extends StatelessWidget {
  final Observation current;
  final bool isBuoy;

  const HeroMetricCard({super.key, required this.current, required this.isBuoy});

  @override
  Widget build(BuildContext context) {
    final bool showWave = isBuoy && current.tideHeight == null;

    return CustomCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (showWave) ...[
            _item("目前波高", "${current.waveHeight ?? '--'} m", Colors.indigo),
            _divider(),
            _item("波浪週期", "${current.wavePeriod ?? '--'} s", Colors.cyan),
          ] else ...[
            _item("目前潮高", "${current.tideHeight ?? '--'} m", const Color(0xFF0077B6)),
            _divider(),
            _item("潮位狀態", current.tideLevel ?? '--', Colors.black87),
          ],
        ],
      ),
    );
  }

  Widget _item(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.rubik(fontSize: 34, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.grey.shade100);
}