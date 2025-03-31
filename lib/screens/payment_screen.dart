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
  String? _selectedDuration;
  List<String> _availableSpotNumbers = [];
  List<String> _paymentMethods = ['Credit Card', 'UPI', 'PayPal'];
  List<String> _durations = ['30 mins', '1 hour', '2 hours', '3+ hours'];
  bool _isLoading = true;
  bool _isBooking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parkingSpots = [
      {
        'id': 'test-unb-spot',
        'name': 'Aitken Centre Parking',
        'lat': 45.9456,
        'lng': -66.6413,
        'available_spaces': 5,
      }
    ];
    _selectedSpot = _parkingSpots[0];
    _updateAvailableSpotNumbers();
    _isLoading = false;
    _fetchParkingSpots();
  }

  Future<void> _fetchParkingSpots() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('parkingspots').get();
      setState(() {
        _parkingSpots = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        if (_parkingSpots.isNotEmpty) {
          _selectedSpot = _parkingSpots[0];
          _updateAvailableSpotNumbers();
        }
      });
    } catch (e) {
      setState(() => _errorMessage = "Failed to fetch parking spots: $e");
    }
  }

  void _updateAvailableSpotNumbers() {
    if (_selectedSpot == null) return;
    final int available =
        int.tryParse(_selectedSpot!["available_spaces"].toString()) ?? 0;
    setState(() {
      _availableSpotNumbers = List.generate(available, (i) => "${i + 1}");
      _selectedSpotNumber =
          _availableSpotNumbers.isNotEmpty ? _availableSpotNumbers[0] : null;
    });
  }

  int _calculateFee() {
    switch (_selectedDuration) {
      case '30 mins':
        return 1;
      case '1 hour':
        return 2;
      case '2 hours':
        return 3;
      case '3+ hours':
        return 5;
      default:
        return 0;
    }
  }

  void _confirmAndBook() async {
    if (_selectedSpot == null ||
        _selectedSpotNumber == null ||
        _selectedPaymentMethod == null ||
        _selectedDuration == null) return;

    final fee = _calculateFee();

    showDialog(
      context: context,
      builder: (context) => ZoomIn(
        child: AlertDialog(
          backgroundColor: Colors.green[50],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Confirm Payment",
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          content: Text(
            "You're about to pay for:\n${_selectedSpot!["name"]}\nSpot: $_selectedSpotNumber\nDuration: $_selectedDuration\nPayment via: $_selectedPaymentMethod\n\nFee: CAD \$${fee.toString()}",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _bookParkingSpot();
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookParkingSpot() async {
    setState(() {
      _isBooking = true;
      _errorMessage = null;
    });
    try {
      await Future.delayed(const Duration(seconds: 1));
      _showBookingSuccess();
    } catch (e) {
      setState(() => _errorMessage = "Failed to pay for parking spot: $e");
    } finally {
      setState(() => _isBooking = false);
    }
  }

  void _showBookingSuccess() {
    final fee = _calculateFee();
    showDialog(
      context: context,
      builder: (context) => BounceInDown(
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
          content: Text(
            "🎉 Payment Confirmed!\n\n${_selectedSpot!["name"]} - $_selectedSpotNumber\nDuration: $_selectedDuration\nPaid: CAD \$${fee.toString()}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Done", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87, // ✅ Now visible on light background
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFe0f7fa), Colors.white], // 💡 Updated colors
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "Pay for Parking",
            style: TextStyle(color: Colors.green),
          ),
          backgroundColor: Colors.white, // 💡 Light AppBar
          iconTheme: const IconThemeData(color: Colors.green),
          elevation: 2,
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.transparent,
          child: SafeArea(
            child: _isBooking
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  )
                : ElevatedButton(
                    onPressed: _availableSpotNumbers.isNotEmpty &&
                            _selectedPaymentMethod != null &&
                            _selectedDuration != null
                        ? _confirmAndBook
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Pay and Book",
                        style: TextStyle(fontSize: 18)),
                  ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            : _parkingSpots.isEmpty
                ? const Center(
                    child: Text("No parking spots available.",
                        style: TextStyle(color: Colors.black54)),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeInDown(
                              child: const Text("Pay for Your Spot",
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                            ),
                            const SizedBox(height: 20),
                            _sectionTitle("1. Choose Location"),
                            DropdownButtonFormField<Map<String, dynamic>>(
                              value: _selectedSpot,
                              onChanged: (spot) {
                                setState(() {
                                  _selectedSpot = spot;
                                  _updateAvailableSpotNumbers();
                                });
                              },
                              items: _parkingSpots.map((spot) {
                                return DropdownMenuItem(
                                  value: spot,
                                  child: Text(spot['name'],
                                      style:
                                          const TextStyle(color: Colors.black)),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    const Color.fromARGB(0, 255, 255, 255),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                                "Available: ${_selectedSpot?["available_spaces"]}",
                                style: const TextStyle(color: Colors.black54)),
                            _sectionTitle("2. Select  Number Spots"),
                            DropdownButtonFormField<String>(
                              value: _selectedSpotNumber,
                              onChanged: (val) =>
                                  setState(() => _selectedSpotNumber = val),
                              items: _availableSpotNumbers
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    const Color.fromARGB(0, 255, 255, 255),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            _sectionTitle("3. Select Duration"),
                            DropdownButtonFormField<String>(
                              value: _selectedDuration,
                              onChanged: (val) =>
                                  setState(() => _selectedDuration = val),
                              items: _durations
                                  .map((d) => DropdownMenuItem(
                                      value: d, child: Text(d)))
                                  .toList(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    const Color.fromARGB(0, 255, 255, 255),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            _sectionTitle("4. Select Payment Method"),
                            DropdownButtonFormField<String>(
                              value: _selectedPaymentMethod,
                              onChanged: (val) =>
                                  setState(() => _selectedPaymentMethod = val),
                              items: _paymentMethods
                                  .map((m) => DropdownMenuItem(
                                      value: m, child: Text(m)))
                                  .toList(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    const Color.fromARGB(0, 255, 255, 255),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 25),
                            if (_errorMessage != null)
                              FadeIn(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
