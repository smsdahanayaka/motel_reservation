import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/booking.dart';
import 'package:my_app/services/database_service.dart';
import 'package:my_app/widgets/date_selector.dart';
import 'package:my_app/widgets/price_summary.dart';

class BookingScreen extends StatefulWidget {
  final String roomType;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;

  const BookingScreen({
    super.key,
    required this.roomType,
    this.initialCheckIn,
    this.initialCheckOut,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  bool _isLoading = false;
  String? _selectedRoom;
  final Map<String, List<double>> _pricing = {
    'Standard Room': [17.0, 30.0, 45.0, 100.0],
    'Penthouse Suite': [65.0, 100.0, 135.0, 220.0, 750.0],
  };

  @override
  void initState() {
    super.initState();
    _checkInDate = widget.initialCheckIn;
    _checkOutDate = widget.initialCheckOut;
  }

  double get _totalPrice {
    if (_checkInDate == null || _checkOutDate == null) return 0.0;
    final days = _checkOutDate!.difference(_checkInDate!).inDays;
    final prices = _pricing[widget.roomType]!;

    if (days >= 30 && widget.roomType == 'Penthouse Suite') {
      return prices[4]; // Monthly rate
    } else if (days >= 7) {
      return prices[3]; // Weekly rate
    } else if (days >= 3) {
      return prices[2]; // 3-day rate
    } else if (days >= 2) {
      return prices[1]; // 2-day rate
    } else {
      return prices[0]; // Daily rate
    }
  }

  Future<void> _submitBooking() async {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select check-in and check-out dates'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DatabaseService().createBooking(
        roomType: widget.roomType,
        checkIn: _checkInDate!,
        checkOut: _checkOutDate!,
        totalPrice: _totalPrice,
        roomNumber: _selectedRoom ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking successful!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book ${widget.roomType}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomType,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPriceTable(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Add Room Dropdown for Standard Room
            if (widget.roomType == 'Standard Room') ...[
              const Text(
                'Select Room',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRoom,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items:
                    [
                      'Room 1',
                      'Room 2',
                      'Room 3',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRoom = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            DateSelector(
              label: 'Check-in Date',
              selectedDate: _checkInDate,
              onDateSelected: (date) {
                setState(() {
                  _checkInDate = date;
                  if (_checkOutDate != null &&
                      _checkOutDate!.isBefore(
                        date.add(const Duration(days: 1)),
                      )) {
                    _checkOutDate = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            DateSelector(
              label: 'Check-out Date',
              selectedDate: _checkOutDate,
              firstDate: _checkInDate?.add(const Duration(days: 1)),
              onDateSelected: (date) => setState(() => _checkOutDate = date),
            ),
            const SizedBox(height: 32),
            if (_checkInDate != null && _checkOutDate != null)
              PriceSummary(
                roomType: widget.roomType,
                checkIn: _checkInDate!,
                checkOut: _checkOutDate!,
                price: _totalPrice,
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Confirm Booking',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTable() {
    final isPenthouse = widget.roomType == 'Penthouse Suite';
    final lkrRate = 300; // Example conversion rate

    return Table(
      border: TableBorder.symmetric(
        inside: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      children: [
        const TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey)),
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Duration',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('USD', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('LKR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('1 day'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('\$${_pricing[widget.roomType]![0]}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${(_pricing[widget.roomType]![0] * lkrRate).toStringAsFixed(0)} LKR',
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('2 days'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('\$${_pricing[widget.roomType]![1]}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${(_pricing[widget.roomType]![1] * lkrRate).toStringAsFixed(0)} LKR',
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('3 days'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('\$${_pricing[widget.roomType]![2]}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${(_pricing[widget.roomType]![2] * lkrRate).toStringAsFixed(0)} LKR',
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('1 week'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('\$${_pricing[widget.roomType]![3]}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${(_pricing[widget.roomType]![3] * lkrRate).toStringAsFixed(0)} LKR',
              ),
            ),
          ],
        ),
        if (isPenthouse)
          TableRow(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('1 month'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('\$${_pricing[widget.roomType]![4]}'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${(_pricing[widget.roomType]![4] * lkrRate).toStringAsFixed(0)} LKR',
                ),
              ),
            ],
          ),
      ],
    );
  }
}
