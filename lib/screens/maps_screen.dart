import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'payment_screen.dart'; // Import PaymentScreen

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _locationError = false;
  bool _mapReady = false;
  String? _errorMessage;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _determinePosition();
    await _fetchParkingSpots();
  }

  Future<void> _determinePosition() async {
    print("📍 Checking location services...");
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print("📍 Service enabled: $serviceEnabled");

    if (!serviceEnabled) {
      return _setLocationError("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    print("📍 Initial permission status: $permission");

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print("📍 Permission after request: $permission");
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Location permission denied");
      return _setLocationError("Location permission denied.");
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      print("✅ Got location: ${position.latitude}, ${position.longitude}");

      _currentLocation = LatLng(position.latitude, position.longitude);
      _updateUserMarker();
      if (_mapReady) _animateToUser();
    } catch (e) {
      print("❌ Location error: $e");
      return _setLocationError("Could not get location.");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _setLocationError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _locationError = true;
        _errorMessage = message;
      });
    }
  }

  void _updateUserMarker() {
    if (_currentLocation == null) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "currentLocation");
      _markers.add(Marker(
        markerId: const MarkerId("currentLocation"),
        position: _currentLocation!,
        infoWindow: const InfoWindow(title: "You are here"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });
  }

  Future<void> _fetchParkingSpots() async {
    try {
      List<Map<String, dynamic>> parkingSpots = [];

      // Try fetching from Firestore
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('parkingspots').get();
      parkingSpots = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      // If no spots are found in Firestore, use a hardcoded spot near UNB
      if (parkingSpots.isEmpty) {
        print("No spots in Firestore, using hardcoded spot");
        parkingSpots = [
          {
            'id': 'test-unb-spot',
            'name': 'Aitken Centre Parking',
            'lat': 45.9456,
            'lng': -66.6413,
            'available_spaces': 25, // Hardcoded 25 available spaces near UNB
          }
        ];
      }

      final Set<Marker> markers = parkingSpots.map((data) {
        return Marker(
          markerId: MarkerId(data['id']),
          position: LatLng(data["lat"], data["lng"]),
          infoWindow: InfoWindow(
            title: data["name"],
            snippet: "Available: ${data["available_spaces"]} spots",
            onTap: () => _navigateToLocation(LatLng(data["lat"], data["lng"])),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        );
      }).toSet();

      if (mounted) {
        setState(() {
          _markers.addAll(markers);
          print("Markers added: ${_markers.length}");
        });
      }
    } catch (e) {
      print("❌ Failed to fetch parking spots: $e");
    }
  }

  void _navigateToLocation(LatLng destination) async {
    if (_currentLocation == null) return;

    final url =
        "https://www.google.com/maps/dir/?api=1&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print("❌ Could not launch URL");
    }
  }

  Future<void> _animateToUser() async {
    if (_mapController != null && _currentLocation != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 17.5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EasyPark Map"),
        actions: [
          IconButton(
            icon: const Icon(Icons.payment),
            onPressed: () {
              print("Payment button tapped");
              try {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentScreen(),
                    ),
                  );
                } else {
                  print("Widget not mounted, cannot navigate.");
                }
              } catch (e) {
                print("Navigation error: $e");
              }
            },
            tooltip: "Pay for Parking",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locationError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage ?? "Error",
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _locationError = false;
                          });
                          _initialize();
                        },
                        child: const Text("Retry"),
                      )
                    ],
                  ),
                )
              : GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: _currentLocation!, zoom: 15),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _mapReady = true;
                    if (_currentLocation != null) _animateToUser();
                  },
                ),
      floatingActionButton: _currentLocation != null
          ? FloatingActionButton(
              onPressed: _animateToUser,
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }
}