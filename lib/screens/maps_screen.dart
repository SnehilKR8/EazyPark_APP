import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'payment_screen.dart';
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
  String? _errorMessage;
  final Set<Marker> _markers = {};
  Map<String, dynamic>? _selectedSpot;
  StreamSubscription? _spotSubscription;

  late BitmapDescriptor userLocationIcon;
  late BitmapDescriptor paidMarkerIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _initialize();
  }

  @override
  void dispose() {
    _spotSubscription?.cancel();
    super.dispose();
  }

  // Future<void> _loadCustomMarkers() async {
  //   userLocationIcon = await BitmapDescriptor.fromAssetImage(
  //     const ImageConfiguration(size: Size(48, 48)),
  //     'assets/icons/custom_marker.png',
  //   );

  //   paidMarkerIcon = await BitmapDescriptor.fromAssetImage(
  //     const ImageConfiguration(size: Size(48, 48)),
  //     'assets/icons/gold_marker.png',
  //   );
  // }

  Future<void> _loadCustomMarkers() async {
    userLocationIcon =
        await getResizedMarker('assets/icons/custom_marker.png', 120);
    paidMarkerIcon =
        await getResizedMarker('assets/icons/gold_marker.png', 120);
  }

  Future<void> _initialize() async {
    await _determinePosition();
    _listenToParkingSpots();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _setLocationError("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _setLocationError("Location permission denied.");
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
      _updateUserMarker();
    } catch (e) {
      return _setLocationError("Could not get location.");
    }

    if (mounted) setState(() => _isLoading = false);
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
        icon: userLocationIcon,
      ));
    });
  }

  void _listenToParkingSpots() {
    _spotSubscription = FirebaseFirestore.instance
        .collection('parkingspots')
        .snapshots()
        .listen((snapshot) {
      final parkingSpots = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      final Set<Marker> markers = parkingSpots.map((data) {
        final int available = data["available_spaces"] ?? 0;
        final int total = data["total_spaces"] ?? 0;
        final String type = (data["type"] ?? "Free").toString();

        BitmapDescriptor icon;
        if (type.toLowerCase() == "paid") {
          icon = paidMarkerIcon;
        } else {
          icon = available == 0
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
              : (available < 5
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange)
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen));
        }

        return Marker(
          markerId: MarkerId(data['id']),
          position: LatLng(data["lat"], data["lng"]),
          onTap: () => _onMarkerTapped(data),
          icon: icon,
          infoWindow: InfoWindow(
            title: data["name"],
            snippet: "${type.toUpperCase()} • $available / $total available",
            onTap: () => _navigateToLocation(LatLng(data["lat"], data["lng"])),
          ),
        );
      }).toSet();

      if (mounted) {
        setState(() {
          _markers.removeWhere((m) => m.markerId.value != "currentLocation");
          _markers.addAll(markers);
        });
      }
    });
  }

  void _onMarkerTapped(Map<String, dynamic> spotData) {
    setState(() => _selectedSpot = spotData);
    _showBottomSheet();
  }

  void _showBottomSheet() {
    if (_selectedSpot == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSpot!["name"] ?? "Parking Spot",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  "Available: ${_selectedSpot!["available_spaces"]} / ${_selectedSpot!["total_spaces"]}",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Type: ${_selectedSpot!["type"] ?? "Free"}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToLocation(
                          LatLng(_selectedSpot!["lat"], _selectedSpot!["lng"]),
                        ),
                        icon: const Icon(Icons.navigation),
                        label: const Text("Navigate"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaymentScreen()),
                        ),
                        icon: const Icon(Icons.payment),
                        label: const Text("Payment"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToLocation(LatLng destination) async {
    if (_currentLocation == null) return;
    final url =
        "https://www.google.com/maps/dir/?api=1&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFe0f7fa), Colors.white],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.green),
          title: Image.asset('assets/images/easypark_logo_transparent.png',
              height: 40),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
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
                        Text(_errorMessage ?? "Error",
                            style: const TextStyle(color: Colors.red)),
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
                : Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition:
                            CameraPosition(target: _currentLocation!, zoom: 15),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: _markers,
                        onMapCreated: (controller) =>
                            _mapController = controller,
                      ),
                      Positioned(
                        bottom: 100,
                        right: 20,
                        child: FloatingActionButton(
                          onPressed: _initialize,
                          backgroundColor: Colors.greenAccent,
                          child: const Icon(Icons.refresh),
                        ),
                      )
                    ],
                  ),
      ),
    );
  }
}
