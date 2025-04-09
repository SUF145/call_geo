import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/location_model.dart';

class LocationList extends StatelessWidget {
  final List<LocationModel> locations;
  final Function(LocationModel)? onLocationTap;

  const LocationList({
    Key? key,
    required this.locations,
    this.onLocationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return const Center(child: Text('No location data available'));
    }

    // Sort locations by timestamp (newest first)
    final sortedLocations = List<LocationModel>.from(locations)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      itemCount: sortedLocations.length,
      itemBuilder: (context, index) {
        final location = sortedLocations[index];
        final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
        final formattedDate = dateFormat.format(location.timestamp.toLocal());
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text('${locations.length - index}'),
            ),
            title: Text(formattedDate),
            subtitle: Text(
              'Lat: ${location.latitude.toStringAsFixed(6)}, '
              'Lng: ${location.longitude.toStringAsFixed(6)}',
            ),
            trailing: Text(
              'Accuracy: ${location.accuracy.toStringAsFixed(1)}m',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: onLocationTap != null ? () => onLocationTap!(location) : null,
          ),
        );
      },
    );
  }
}
