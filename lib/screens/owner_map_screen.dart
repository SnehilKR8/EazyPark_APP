// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class OwnerMapScreen extends StatefulWidget {
//   const OwnerMapScreen({Key? key}) : super(key: key);

//   @override
//   _OwnerMapScreenState createState() => _OwnerMapScreenState();
// }

// class _OwnerMapScreenState extends State<OwnerMapScreen> {
//   final Completer<GoogleMapController> _controller = Completer();
//   final Location _location = Location();
//   LatLng? _currentPosition;
//   LatLng? _selectedLocation;

//   final TextEditingController _parkingNameController = TextEditingController();
//   final TextEditingController _totalSpacesController = TextEditingController();
//   final TextEditingController _availableSpacesController =
//       TextEditingController();

//   final Set<Marker> _markers = {};
//   late BitmapDescriptor _customMarker;
//   bool _isLoading = true;
//   StreamSubscription? _spotSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _loadCustomMarker();
//     _getCurrentLocation();
//     _listenToRealTimeSpots(); // 🔁 Real-time update
//   }

//   @override
//   void dispose() {
//     _spotSubscription?.cancel();
//     super.dispose();
//   }

//   Future<void> _loadCustomMarker() async {
//     _customMarker = await BitmapDescriptor.fromAssetImage(
//       const ImageConfiguration(size: Size(48, 48)),
//       'assets/icons/custom_marker.png',
//     );
//   }

//   Future<void> _getCurrentLocation() async {
//     final locData = await _location.getLocation();
//     _currentPosition = LatLng(locData.latitude!, locData.longitude!);
//     _updateCurrentUserMarker();
//     setState(() => _isLoading = false);
//   }

//   void _updateCurrentUserMarker() {
//     if (_currentPosition == null) return;
//     _markers.removeWhere((m) => m.markerId.value == 'current_location');
//     _markers.add(
//       Marker(
//         markerId: const MarkerId('current_location'),
//         position: _currentPosition!,
//         icon: _customMarker,
//         infoWindow: const InfoWindow(title: 'Your Location'),
//       ),
//     );
//     setState(() {});
//   }

//   void _listenToRealTimeSpots() {
//     _spotSubscription = FirebaseFirestore.instance
//         .collection('parkingspots')
//         .snapshots()
//         .listen((snapshot) {
//       final newMarkers = snapshot.docs.map((doc) {
//         final data = doc.data();
//         final available = data['available_spaces'] ?? 0;
//         final total = data['total_spaces'] ?? 0;

//         final icon = available == 0
//             ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
//             : (available < 5
//                 ? BitmapDescriptor.defaultMarkerWithHue(
//                     BitmapDescriptor.hueYellow)
//                 : BitmapDescriptor.defaultMarkerWithHue(
//                     BitmapDescriptor.hueGreen));

//         return Marker(
//           markerId: MarkerId(doc.id),
//           position: LatLng(data['lat'], data['lng']),
//           icon: icon,
//           infoWindow: InfoWindow(
//             title: data['name'],
//             snippet: '$available / $total available',
//             onTap: () => _confirmDelete(doc.id),
//           ),
//         );
//       }).toSet();

//       setState(() {
//         _markers.removeWhere((m) => m.markerId.value != 'current_location');
//         _markers.addAll(newMarkers);
//       });
//     });
//   }

//   void _onTap(LatLng pos) {
//     setState(() => _selectedLocation = pos);
//     _showSaveDialog();
//   }

//   Future<void> _showSaveDialog() async {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Add Parking Spot'),
//           content: SingleChildScrollView(
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _parkingNameController,
//                   decoration:
//                       const InputDecoration(labelText: 'Parking Lot Name'),
//                 ),
//                 TextField(
//                   controller: _totalSpacesController,
//                   keyboardType: TextInputType.number,
//                   decoration: const InputDecoration(labelText: 'Total Spaces'),
//                 ),
//                 TextField(
//                   controller: _availableSpacesController,
//                   keyboardType: TextInputType.number,
//                   decoration:
//                       const InputDecoration(labelText: 'Available Spaces'),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel')),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _saveParkingLocation();
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _saveParkingLocation() async {
//     if (_selectedLocation == null ||
//         _parkingNameController.text.trim().isEmpty) {
//       print("❌ Missing fields.");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('❗ Please fill all fields')),
//       );
//       return;
//     }

//     final total = int.tryParse(_totalSpacesController.text.trim()) ?? 10;
//     final available =
//         int.tryParse(_availableSpacesController.text.trim()) ?? 10;

//     final spotData = {
//       'name': _parkingNameController.text.trim(),
//       'lat': _selectedLocation!.latitude,
//       'lng': _selectedLocation!.longitude,
//       'total_spaces': total,
//       'available_spaces': available,
//     };

//     print("📡 Uploading marker to Firestore: $spotData");

//     try {
//       final docRef = await FirebaseFirestore.instance
//           .collection('parkingspots')
//           .add(spotData)
//           .timeout(const Duration(seconds: 10));

//       print("✅ Marker uploaded successfully. ID: ${docRef.id}");

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("✅ Location saved with ID: ${docRef.id}")),
//       );

//       _parkingNameController.clear();
//       _totalSpacesController.clear();
//       _availableSpacesController.clear();
//     } catch (e, stackTrace) {
//       print("❌ Firestore write error: $e");
//       print("📛 Stacktrace:\n$stackTrace");

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ Failed to save location: $e")),
//       );
//     }
//   }

//   void _confirmDelete(String docId) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Delete Spot"),
//         content:
//             const Text("Are you sure you want to delete this parking spot?"),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(ctx);
//               await FirebaseFirestore.instance
//                   .collection('parkingspots')
//                   .doc(docId)
//                   .delete();
//             },
//             child: const Text("Delete"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFFf0f4f8), Colors.white],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 2,
//           iconTheme: const IconThemeData(color: Colors.orange),
//           title: Row(
//             children: [
//               const Text(
//                 'Set your ',
//                 style: TextStyle(
//                     color: Colors.orange, fontWeight: FontWeight.bold),
//               ),
//               Image.asset('assets/images/easypark_logo_transparent.png',
//                   height: 30),
//             ],
//           ),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.refresh, color: Colors.orange),
//               onPressed: () => _getCurrentLocation(),
//             ),
//           ],
//         ),
//         body: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : GoogleMap(
//                 initialCameraPosition:
//                     CameraPosition(target: _currentPosition!, zoom: 15),
//                 markers: _markers,
//                 onMapCreated: (controller) => _controller.complete(controller),
//                 onLongPress: _onTap,
//                 myLocationEnabled: true,
//                 myLocationButtonEnabled: true,
//               ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final Set<Marker> _markers = {};
  late BitmapDescriptor _customMarker;
  bool _isLoading = true;
  StreamSubscription? _spotSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // Initialize marker, current location and Firestore listener
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

  // Load a custom marker from assets
  Future<void> _loadCustomMarker() async {
    _customMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/icons/custom_marker.png',
    );
  }

  // Get device's current location
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

  // Update the marker for user's location
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

  // Listen to real-time updates from Firestore "parkingspots" collection
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
            final icon = available == 0
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                : (available < 5
                    ? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueYellow)
                    : BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen));

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
        // Keep current location marker intact
        _markers.removeWhere((m) => m.markerId.value != 'current_location');
        _markers.addAll(newMarkers);
      });
    });
  }

  // On long press, select location and show dialog to add a parking spot
  void _onLongPress(LatLng pos) {
    setState(() {
      _selectedLocation = pos;
    });
    _showSaveDialog();
  }

  // Display dialog for adding parking spot details
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
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
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

  // Save the parking spot to Firestore
  Future<void> _saveParkingLocation() async {
    if (_selectedLocation == null) {
      print("No location selected.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No location selected. Please long press on the map to select a location.')),
      );
      return;
    }
    if (_parkingNameController.text.trim().isEmpty) {
      print("Parking name is empty.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parking name is required.')),
      );
      return;
    }

    final int total = int.tryParse(_totalSpacesController.text.trim()) ?? 10;
    final int available =
        int.tryParse(_availableSpacesController.text.trim()) ?? 10;

    final Map<String, dynamic> spotData = {
      'name': _parkingNameController.text.trim(),
      'lat': _selectedLocation!.latitude,
      'lng': _selectedLocation!.longitude,
      'total_spaces': total,
      'available_spaces': available,
    };

    print("Attempting to save spotData: $spotData");

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('parkingspots')
          .add(spotData)
          .timeout(const Duration(seconds: 10));
      print("Spot saved with ID: ${docRef.id}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location saved with ID: ${docRef.id}")),
      );

      // Clear fields after successful save
      _parkingNameController.clear();
      _totalSpacesController.clear();
      _availableSpacesController.clear();
    } catch (e, stackTrace) {
      print("Error saving spotData: $e");
      print("Stacktrace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save location: $e")),
      );
    }
  }

  // Confirm deletion of a parking spot
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
              try {
                await FirebaseFirestore.instance
                    .collection('parkingspots')
                    .doc(docId)
                    .delete();
                print("Spot $docId deleted successfully.");
              } catch (e) {
                print("Error deleting spot: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete spot: $e")));
              }
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
            const Text('Set your ',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold)),
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
