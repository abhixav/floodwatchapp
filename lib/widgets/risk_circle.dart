import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/area_model.dart';

CircleMarker buildRiskCircle(Area a) {
  return CircleMarker(
    point: a.center,
    useRadiusInMeter: true,
    radius: a.radiusMeters,
    color: a.risk.color.withOpacity(.28),
    borderColor: a.risk.color.withOpacity(.9),
    borderStrokeWidth: 2,
  );
}

Marker buildAreaDot(Area a) {
  return Marker(
    point: a.center,
    width: 12,
    height: 12,
    // 'child' is the new API in flutter_map 8.x
    child: Container(
      decoration: BoxDecoration(
        color: a.risk.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
    ),
  );
}

Widget buildLegendCard() {
  Widget row(Color c, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(t),
          ],
        ),
      );

  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Risk Levels', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          row(RiskLevel.severe.color, RiskLevel.severe.label),
          row(RiskLevel.high.color, RiskLevel.high.label),
          row(RiskLevel.moderate.color, RiskLevel.moderate.label),
          row(RiskLevel.safe.color, RiskLevel.safe.label),
          const SizedBox(height: 6),
          const Text('Circles denote area-wise risk', style: TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}
