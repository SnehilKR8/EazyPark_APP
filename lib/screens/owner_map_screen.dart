import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class OwnerMapScreen extends StatefulWidget {
  const OwnerMapScreen({super.key});

  @override
  State<OwnerMapScreen> createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends State<OwnerMapScreen> {
  LatLng? _selectedPosition;
  late GoogleMapController _mapController;

  void _onLongPress(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });

    _showAddSpotDialog(position);
  }

  Future<void> _showAddSpotDialog(LatLng position) async {
    final nameController = TextEditingController();
    final spacesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Parking Spot"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Parking Name"),
            ),
            TextField(
              controller: spacesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Available Spaces"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final spacesText = spacesController.text.trim();

              if (name.isEmpty ||
                  spacesText.isEmpty ||
                  _selectedPosition == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("Please fill all fields and select location.")),
                );
                return;
              }

              try {
                final spaces = int.parse(spacesText);

                await FirebaseFirestore.instance
                    .collection("parkingspots")
                    .add({
                  "name": name,
                  "available_spaces": spaces,
                  "lat": _selectedPosition!.latitude,
                  "lng": _selectedPosition!.longitude,
                  "created_at": Timestamp.now(),
                  "added_by": "owner",
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("✅ Parking spot saved.")),
                );
              } catch (e) {
                print("❌ Error saving spot: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Failed to save: $e")),
                );
              }

              Navigator.pop(context);
              setState(() {
                _selectedPosition = null;
              });
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<LatLng> _getInitialLocation() async {
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng>(
      future: _getInitialLocation(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final current = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text("Mark Parking Location")),
          body: GoogleMap(
            initialCameraPosition: CameraPosition(target: current, zoom: 15),
            onMapCreated: (controller) => _mapController = controller,
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: MarkerId("selected"),
                      position: _selectedPosition!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen),
                    )
                  }
                : {},
            onLongPress: _onLongPress,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
        );
      },
    );
  }
}
