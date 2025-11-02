import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            const _AlertSection(),
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

class _AlertSection extends StatelessWidget {
  const _AlertSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final alert = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        final title = alert['title'] ?? 'New Alert';
        final message =
            alert['message'] ?? 'Stay alert and follow safety measures.';
        final severity = alert['severity'] ?? 'Moderate';
        final area = alert['targetArea'] ?? 'All Trivandrum Areas';

        Color bgColor;
        switch (severity.toLowerCase()) {
          case 'critical':
            bgColor = AppColors.severe;
            break;
          case 'high':
            bgColor = AppColors.high;
            break;
          case 'moderate':
            bgColor = AppColors.moderate;
            break;
          default:
            bgColor = Colors.blueGrey;
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bgColor.withOpacity(0.85),
                bgColor.withOpacity(0.65),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: bgColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notifications_active,
                  color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(message,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('Severity: $severity • Area: $area',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: area.risk.color.withOpacity(.2),
          child: Icon(Icons.water_drop, color: area.risk.color),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(area.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Rainfall: ${area.rainfall.toStringAsFixed(1)} mm',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              area.risk.color.withOpacity(.8),
              area.risk.color.withOpacity(.6),
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(area.risk.label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}
