import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Map<String, dynamic>> _parkingSpots = [];
  Map<String, dynamic>? _selectedSpot;
  String? _selectedSpotNumber;
  String? _selectedPaymentMethod;
  List<String> _availableSpotNumbers = [];
  List<String> _paymentMethods = ['Credit Card', 'UPI', 'PayPal'];
  bool _isLoading = true;
  bool _isBooking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize with hardcoded data to load the page instantly
    _parkingSpots = [
      {
        'id': 'test-unb-spot',
        'name': 'Aitken Centre Parking',
        'lat': 45.9456,
        'lng': -66.6413,
        'available_spaces': 5, // Hardcoded 5 available spaces for testing
      }
    ];
    _selectedSpot = _parkingSpots[0];
    _updateAvailableSpotNumbers();
    _isLoading = false;

    // Fetch Firestore data in the background
    _fetchParkingSpots();
  }

  Future<void> _fetchParkingSpots() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('parkingspots').get();
      setState(() {
        _parkingSpots = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();

        // If no spots are found in Firestore, keep the hardcoded spot
        if (_parkingSpots.isEmpty) {
          _parkingSpots = [
            {
              'id': 'test-unb-spot',
              'name': 'Aitken Centre Parking',
              'lat': 45.9456,
              'lng': -66.6413,
              'available_spaces': 5,
            }
          ];
        }

        if (_parkingSpots.isNotEmpty) {
          _selectedSpot = _parkingSpots[0];
          _updateAvailableSpotNumbers();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch parking spots: $e";
      });
    }
  }

  void _updateAvailableSpotNumbers() {
    if (_selectedSpot == null) return;
    final int availableSpaces = int.parse(_selectedSpot!['available_spaces'].toString());
    setState(() {
      _availableSpotNumbers = List.generate(availableSpaces, (index) => "Spot ${index + 1}");
      _selectedSpotNumber = _availableSpotNumbers.isNotEmpty ? _availableSpotNumbers[0] : null;
    });
  }

  Future<void> _bookParkingSpot() async {
    if (_selectedSpot == null || _selectedSpotNumber == null || _selectedPaymentMethod == null) return;

    setState(() {
      _isBooking = true;
      _errorMessage = null;
    });

    try {
      // If using the hardcoded spot, simulate booking without Firestore update
      if (_selectedSpot!['id'] == 'test-unb-spot') {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        _showBookingSuccess();
        return;
      }

      // Update Firestore: decrement available spaces
      await FirebaseFirestore.instance
          .collection('parkingspots')
          .doc(_selectedSpot!['id'])
          .update({
        'available_spaces': FieldValue.increment(-1),
      });

      _showBookingSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to book parking spot: $e";
      });
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  void _showBookingSuccess() {
    showDialog(
      context: context,
      builder: (context) => FadeIn(
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 50,
          ),
          content: Text(
            "Successfully booked ${_selectedSpot!['name']} - $_selectedSpotNumber\nPayment via $_selectedPaymentMethod",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to map
              },
              child: const Text(
                "Back to Map",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pay for Parking"),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[200]!],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _parkingSpots.isEmpty
                ? const Center(
                    child: Text(
                      "No parking spots available.",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          child: const Text(
                            "Reserve Your Parking Spot",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeInLeft(
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Select a Parking Location:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButton<Map<String, dynamic>>(
                                    value: _selectedSpot,
                                    onChanged: (Map<String, dynamic>? newValue) {
                                      setState(() {
                                        _selectedSpot = newValue;
                                        _updateAvailableSpotNumbers();
                                      });
                                    },
                                    items: _parkingSpots.map<DropdownMenuItem<Map<String, dynamic>>>(
                                        (Map<String, dynamic> spot) {
                                      return DropdownMenuItem<Map<String, dynamic>>(
                                        value: spot,
                                        child: Text(spot['name']),
                                      );
                                    }).toList(),
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                  const SizedBox(height: 20),
                                  if (_selectedSpot != null) ...[
                                    Text(
                                      "Location: ${_selectedSpot!['lat']}, ${_selectedSpot!['lng']}",
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                    Text(
                                      "Available Spaces: ${_selectedSpot!['available_spaces']}",
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                    const SizedBox(height: 20),
                                    if (_availableSpotNumbers.isNotEmpty) ...[
                                      const Text(
                                        "Select a Spot:",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      DropdownButton<String>(
                                        value: _selectedSpotNumber,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedSpotNumber = newValue;
                                          });
                                        },
                                        items: _availableSpotNumbers
                                            .map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        isExpanded: true,
                                        dropdownColor: Colors.white,
                                        style: const TextStyle(color: Colors.black87),
                                      ),
                                    ] else ...[
                                      const Text(
                                        "No available spots at this location.",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeInRight(
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Payment Method:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButton<String>(
                                    value: _selectedPaymentMethod,
                                    hint: const Text("Select Payment Method"),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedPaymentMethod = newValue;
                                      });
                                    },
                                    items: _paymentMethods
                                        .map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "Scan QR Code to Pay:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/QR_code_for_mobile_English_Wikipedia.svg/1200px-QR_code_for_mobile_English_Wikipedia.svg.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Text(
                                                "Failed to load QR code",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_errorMessage != null) ...[
                          FadeIn(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        FadeInUp(
                          child: Center(
                            child: _isBooking
                                ? const CircularProgressIndicator(color: Colors.white)
                                : ElevatedButton(
                                    onPressed: _availableSpotNumbers.isNotEmpty &&
                                            _selectedPaymentMethod != null
                                        ? _bookParkingSpot
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[800],
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 40, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const Text(
                                      "Pay and Book",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}