import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_appbar.dart';
import '../services/data_service.dart';
import '../models/area_model.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final areas = context.watch<DataService>().areas;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'FloodWatch',
        subtitle: 'Trivandrum Flood Monitor',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _AlertCard(areas: areas),
            const SizedBox(height: 16),
            const _SearchField(),
            const SizedBox(height: 20),
            Text(
              'Flood Risk Areas',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 12),
            ...areas.map((a) => _AreaRow(area: a)).toList(),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final List<Area> areas;
  const _AlertCard({required this.areas});

  @override
  Widget build(BuildContext context) {
    final highCount =
        areas.where((a) => a.risk == RiskLevel.high || a.risk == RiskLevel.severe).length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.severe.withOpacity(.8), AppColors.high.withOpacity(.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '$highCount areas at High/Severe risk',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.severe,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search locality...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}

class _AreaRow extends StatelessWidget {
  final Area area;
  const _AreaRow({required this.area});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: area.risk.color.withOpacity(.2),
          child: Icon(Icons.water_drop, color: area.risk.color),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              area.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Rainfall: ${area.rainfall.toStringAsFixed(1)} mm',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [area.risk.color.withOpacity(.8), area.risk.color.withOpacity(.6)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            area.risk.label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
