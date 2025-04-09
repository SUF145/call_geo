import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/location_model.dart';

class DateGroupedLocationList extends StatefulWidget {
  final List<LocationModel> locations;
  final Function(List<LocationModel>)? onDateSelected;
  final Function(LocationModel)? onLocationTap;

  const DateGroupedLocationList({
    super.key,
    required this.locations,
    this.onDateSelected,
    this.onLocationTap,
  });

  @override
  State<DateGroupedLocationList> createState() =>
      _DateGroupedLocationListState();
}

class _DateGroupedLocationListState extends State<DateGroupedLocationList> {
  // Map to store grouped locations by date
  Map<String, List<LocationModel>> _groupedLocations = {};

  // Currently expanded date
  String? _expandedDate;

  // Most recent date (for initial selection)
  String? _mostRecentDate;

  @override
  void initState() {
    super.initState();
    // Delay the initial grouping to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _groupLocationsByDate();
    });
  }

  @override
  void didUpdateWidget(DateGroupedLocationList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locations != oldWidget.locations) {
      _groupLocationsByDate();
    }
  }

  void _groupLocationsByDate() {
    // Clear existing groups
    _groupedLocations = {};

    // Sort locations by timestamp (newest first)
    final sortedLocations = List<LocationModel>.from(widget.locations)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Group locations by date
    for (var location in sortedLocations) {
      final dateKey = DateFormat('yyyy-MM-dd').format(location.timestamp);

      if (!_groupedLocations.containsKey(dateKey)) {
        _groupedLocations[dateKey] = [];
      }

      _groupedLocations[dateKey]!.add(location);
    }

    // Set the most recent date as the initially expanded date
    if (_groupedLocations.isNotEmpty && _expandedDate == null) {
      _mostRecentDate = _groupedLocations.keys.first;
      _expandedDate = _mostRecentDate;

      // Notify parent about the initial date selection
      if (widget.onDateSelected != null && _expandedDate != null) {
        widget.onDateSelected!(_groupedLocations[_expandedDate]!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locations.isEmpty) {
      return const Center(child: Text('No location data available'));
    }

    return ListView.builder(
      itemCount: _groupedLocations.length,
      itemBuilder: (context, index) {
        final dateKey = _groupedLocations.keys.elementAt(index);
        final locationsForDate = _groupedLocations[dateKey]!;
        final isExpanded = dateKey == _expandedDate;

        // Format the date for display
        final date = DateTime.parse(dateKey);
        final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              // Date header (always visible)
              ListTile(
                title: Text(
                  formattedDate,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${locationsForDate.length} locations'),
                trailing: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedDate = null;
                    } else {
                      _expandedDate = dateKey;

                      // Notify parent about the date selection
                      if (widget.onDateSelected != null) {
                        widget.onDateSelected!(locationsForDate);
                      }
                    }
                  });
                },
              ),

              // Expandable list of locations for this date
              if (isExpanded)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: locationsForDate.length,
                  itemBuilder: (context, locationIndex) {
                    final location = locationsForDate[locationIndex];
                    final formattedTime =
                        DateFormat('h:mm a').format(location.timestamp);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).primaryColor.withAlpha(179),
                        child: Text('${locationIndex + 1}'),
                      ),
                      title: Text(formattedTime),
                      subtitle: Text(
                        'Lat: ${location.latitude.toStringAsFixed(6)}, '
                        'Lng: ${location.longitude.toStringAsFixed(6)}',
                      ),
                      trailing: Text(
                        'Accuracy: ${location.accuracy.toStringAsFixed(1)}m',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: widget.onLocationTap != null
                          ? () => widget.onLocationTap!(location)
                          : null,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
