import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_appbar.dart';
import '../services/data_service.dart';
import '../models/area_model.dart';
import '../utils/app_colors.dart';

// Assuming Area and its Risk property, DataService, and AppColors are correctly imported.

// 1. Convert to a StatefulWidget to manage the search query state (Maintained from previous fix)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get all areas from the Provider
    final allAreas = context.watch<DataService>().areas;

    // Filtering Logic
    final filteredAreas = allAreas.where((area) {
      if (_searchQuery.isEmpty) return true;
      // Case-insensitive search on the area name
      return area.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Slightly lighter background
      appBar: const CustomAppBar(
        title: 'FloodWatch',
        subtitle: 'Trivandrum Flood Monitor',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32), // Adjusted padding
          children: [
            const _AlertSection(),
            const SizedBox(height: 24), // Reduced spacing
            _SearchField(controller: _searchController),
            const SizedBox(height: 28),
            Text(
              _searchQuery.isEmpty
                  ? 'Flood Risk Areas'
                  : 'Search Results (${filteredAreas.length})',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith( // Used headlineSmall for better hierarchy
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 16),
            if (filteredAreas.isEmpty && _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Center(
                  child: Text('No results found for "$_searchQuery".',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ),
              ),
            // Use the filtered list here
            ...filteredAreas.map((a) => _AreaRow(area: a)).toList(),
          ],
        ),
      ),
    );
  }
}

// ---
// ## Alert Section (Minimalist Alert Banner) - Styling Updated
// ---

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
        Color textColor;
        IconData icon;

        switch (severity.toLowerCase()) {
          case 'critical':
          case 'high':
            bgColor = AppColors.severe.withOpacity(0.15); // Slightly richer background
            textColor = AppColors.severe;
            icon = Icons.flash_on_rounded;
            break;
          case 'moderate':
            bgColor = AppColors.moderate.withOpacity(0.15);
            textColor = AppColors.moderate;
            icon = Icons.warning_amber_rounded;
            break;
          default:
            bgColor = Colors.blue.shade100;
            textColor = Colors.blue.shade700;
            icon = Icons.info_outline;
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16), // Softer corners
            border: Border.all(color: textColor.withOpacity(0.3), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: textColor, size: 30), // Slightly larger icon
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, // Bolder title
                          fontSize: 16,
                          color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text('Severity: $severity • Area: $area',
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
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

// ---
// ## Search Field (Updated Styling)
// ---

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // Use the controller from HomeScreen
      cursorColor: Theme.of(context).primaryColor,
      decoration: InputDecoration(
        hintText: 'Search locality...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor), // Highlight search icon
        suffixIcon: controller.text.isNotEmpty // Add a clear button
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  controller.clear();
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        // Use a subtle elevation via shadow instead of heavy border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Remove default border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
      ),
    );
  }
}

// ---
// ## Area Row (Visual Hierarchy and Icons Improved)
// ---

class _AreaRow extends StatelessWidget {
  final Area area;
  const _AreaRow({required this.area});

  // Helper method to determine the label color based on risk level
  Color _getRiskColor() => area.risk.color;

  // Helper method to determine the card background color based on risk level
  Color _getCardBackgroundColor() => _getRiskColor().withOpacity(0.05);

  IconData _getRiskIcon() {
    if (area.risk.label.toLowerCase() == 'severe') return Icons.warning_rounded;
    if (area.risk.label.toLowerCase() == 'moderate') return Icons.water_drop_rounded;
    return Icons.shield_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // Added subtle elevation for better pop-out effect
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Rounded corners
        side: BorderSide(color: _getRiskColor().withOpacity(0.2), width: 1.5), // Colored left border effect
      ),
      color: _getCardBackgroundColor(), // Apply light color based on risk
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area title + risk tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(_getRiskIcon(), color: _getRiskColor(), size: 28), // Risk Icon
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(area.name,
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                  fontWeight: FontWeight.w800, color: Colors.black)), // Bolder name
                          const SizedBox(height: 4),
                          Text('Current Rainfall: ${area.rainfall.toStringAsFixed(1)} mm', // Better label
                              style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Risk Status Chip (Clean background, colored text/border)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRiskColor(), // Solid color chip
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(area.risk.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white, // White text on solid background
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 🔹 7-day rainfall forecast (Progress Indicator Bar)
            if (area.forecast.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('7-Day Rainfall Forecast (mm):',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                  const SizedBox(height: 16),
                  // PASSES ONLY THE FIRST 7 ELEMENTS
                  _ForecastChart(forecast: area.forecast.take(7).toList(),currentRainfall: area.rainfall,),

                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---
// New Widget: Forecast Chart (Visual Polish)
// ---

class _ForecastChart extends StatelessWidget {
  final List<double> forecast;
  final double currentRainfall;
  const _ForecastChart({required this.forecast, required this.currentRainfall});

  static const double _maxRainfall = 50.0;
  static const double _barWidth = 14;

  double _getNormalizedValue(double rainfall) =>
      (rainfall / _maxRainfall).clamp(0.0, 1.0);

  Color _getBarColor(double rainfall) {
    if (rainfall > 40) return AppColors.severe;
    if (rainfall > 20) return AppColors.moderate;
    if (rainfall > 10) return Colors.lightBlue.shade700;
    return Colors.blue.shade400;
  }

  @override
  Widget build(BuildContext context) {
    // Merge current rainfall into the first day
    final updatedForecast = List<double>.from(forecast);
    if (updatedForecast.isNotEmpty) updatedForecast[0] = currentRainfall;

    return SizedBox(
      height: 130,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: updatedForecast.asMap().entries.map((entry) {
          int index = entry.key;
          double rainfall = entry.value;
          double normalizedValue = _getNormalizedValue(rainfall);
          double barHeight = 80;

          bool isToday = index == 0;
          final barColor = _getBarColor(rainfall);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${rainfall.toStringAsFixed(1)}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.black : Colors.black87),
              ),
              const SizedBox(height: 6),
              Container(
                height: barHeight,
                width: _barWidth,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(_barWidth / 2),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: barHeight * normalizedValue,
                    width: _barWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          barColor,
                          barColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(_barWidth / 2),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isToday ? 'Today' : 'Day ${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isToday ? Colors.black : Colors.black54,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
