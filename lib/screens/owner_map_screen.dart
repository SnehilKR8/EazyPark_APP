import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:typed_data';

Future<BitmapDescriptor> getResizedMarker(String assetPath, int width) async {
  ByteData data = await rootBundle.load(assetPath);
  ui.Codec codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: width,
  );
  ui.FrameInfo fi = await codec.getNextFrame();
  final byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}

class OwnerMapScreen extends StatefulWidget {
  const OwnerMapScreen({Key? key}) : super(key: key);

  @override
  _OwnerMapScreenState createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends State<OwnerMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();
  LatLng? _currentPosition;
  LatLng? _selectedLocation;

  final TextEditingController _parkingNameController = TextEditingController();
  final TextEditingController _totalSpacesController = TextEditingController();
  final TextEditingController _availableSpacesController =
      TextEditingController();
  String _parkingType = 'Free'; // 👈 NEW

  final Set<Marker> _markers = {};
  late BitmapDescriptor _customMarker;
  late BitmapDescriptor _goldMarker; // 👈 NEW

  bool _isLoading = true;
  StreamSubscription? _spotSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCustomMarker();
    await _getCurrentLocation();
    _listenToRealTimeSpots();
  }

  @override
  void dispose() {
    _spotSubscription?.cancel();
    _parkingNameController.dispose();
    _totalSpacesController.dispose();
    _availableSpacesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomMarker() async {
    _customMarker =
        await getResizedMarker('assets/icons/custom_marker.png', 120);
    _goldMarker = await getResizedMarker('assets/icons/gold_marker.png', 120);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locData = await _location.getLocation();
      setState(() {
        _currentPosition = LatLng(locData.latitude!, locData.longitude!);
      });
      _updateCurrentUserMarker();
    } catch (e) {
      print("Error getting location: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateCurrentUserMarker() {
    if (_currentPosition == null) return;
    _markers.removeWhere((m) => m.markerId.value == 'current_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition!,
        icon: _customMarker,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
  }

  void _listenToRealTimeSpots() {
    _spotSubscription = FirebaseFirestore.instance
        .collection('parkingspots')
        .snapshots()
        .listen((snapshot) {
      final newMarkers = snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data['lat'] == null ||
                data['lng'] == null ||
                data['name'] == null) {
              return null;
            }
            final int available = data['available_spaces'] ?? 0;
            final int total = data['total_spaces'] ?? 0;
            final String type = data['type'] ?? 'Free';

            // final icon = type == 'Paid'
            //     ? BitmapDescriptor.defaultMarkerWithHue(
            //         BitmapDescriptor.hueYellow)
            //     : (available == 0
            //         ? BitmapDescriptor.defaultMarkerWithHue(
            //             BitmapDescriptor.hueRed)
            //         : (available < 5
            //             ? BitmapDescriptor.defaultMarkerWithHue(
            //                 BitmapDescriptor.hueOrange)
            //             : BitmapDescriptor.defaultMarkerWithHue(
            //                 BitmapDescriptor.hueGreen)));
            final icon = type == 'Paid'
                ? _goldMarker // 👈 use golden icon for paid
                : (available == 0
                    ? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed)
                    : (available < 5
                        ? BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueOrange)
                        : BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen)));

            return Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(data['lat'], data['lng']),
              icon: icon,
              infoWindow: InfoWindow(
                title: data['name'],
                snippet: '$available / $total available',
                onTap: () => _confirmDelete(doc.id),
              ),
            );
          })
          .whereType<Marker>()
          .toSet();

      setState(() {
        _markers.removeWhere((m) => m.markerId.value != 'current_location');
        _markers.addAll(newMarkers);
      });
    });
  }

  void _onLongPress(LatLng pos) {
    setState(() {
      _selectedLocation = pos;
    });
    _showSaveDialog();
  }

  Future<void> _showSaveDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Parking Spot'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _parkingNameController,
                  decoration:
                      const InputDecoration(labelText: 'Parking Lot Name'),
                ),
                TextField(
                  controller: _totalSpacesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Spaces'),
                ),
                TextField(
                  controller: _availableSpacesController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Available Spaces'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _parkingType,
                  decoration: const InputDecoration(labelText: 'Parking Type'),
                  items: ['Free', 'Paid'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _parkingType = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveParkingLocation();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveParkingLocation() async {
    if (_selectedLocation == null ||
        _parkingNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ Please fill all fields')),
      );
      return;
    }

    final total = int.tryParse(_totalSpacesController.text.trim()) ?? 10;
    final available =
        int.tryParse(_availableSpacesController.text.trim()) ?? 10;

    final spotData = {
      'name': _parkingNameController.text.trim(),
      'lat': _selectedLocation!.latitude,
      'lng': _selectedLocation!.longitude,
      'total_spaces': total,
      'available_spaces': available,
      'type': _parkingType, // 👈 include in Firestore
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('parkingspots')
          .add(spotData)
          .timeout(const Duration(seconds: 10));
      print("✅ Spot saved: ${docRef.id}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Saved: ${docRef.id}")),
      );

      _parkingNameController.clear();
      _totalSpacesController.clear();
      _availableSpacesController.clear();
    } catch (e) {
      print("❌ Firestore error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: $e")),
      );
    }
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Spot"),
        content:
            const Text("Are you sure you want to delete this parking spot?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('parkingspots')
                  .doc(docId)
                  .delete();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Set your ',
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            Image.asset('assets/images/easypark_logo_transparent.png',
                height: 30),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.orange),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: _isLoading || _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _currentPosition!, zoom: 15),
              markers: _markers,
              onMapCreated: (controller) => _controller.complete(controller),
              onLongPress: _onLongPress,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
