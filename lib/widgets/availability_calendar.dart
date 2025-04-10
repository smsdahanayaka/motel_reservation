import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailabilityCalendar extends StatefulWidget {
  final String roomType;
  final Function(DateTime?, DateTime?)? onDatesSelected;

  const AvailabilityCalendar({
    Key? key,
    required this.roomType,
    this.onDatesSelected,
  }) : super(key: key);

  @override
  _AvailabilityCalendarState createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  Set<DateTime> _bookedDates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _loadBookedDates();
  }

  Future<void> _loadBookedDates() async {
    try {
      final now = DateTime.now();
      final bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('roomType', isEqualTo: widget.roomType)
          .where('status', isEqualTo: 'Approved')
          .get();

      Set<DateTime> bookedDates = {};

      for (var doc in bookings.docs) {
        final data = doc.data();
        final checkIn = (data['checkIn'] as Timestamp).toDate();
        final checkOut = (data['checkOut'] as Timestamp).toDate();
          print("Booking Document ID: ${doc.id}");
          print("Room Type: ${data['roomType']}");
          print("Check-in: $checkIn");
          print("Check-out: $checkOut");
        // Add all dates between checkIn and checkOut (inclusive)
        DateTime current = DateTime(checkIn.year, checkIn.month, checkIn.day);
        final endDate = DateTime(checkOut.year, checkOut.month, checkOut.day);

        while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
          bookedDates.add(DateTime(current.year, current.month, current.day));
          current = current.add(const Duration(days: 1));
        }
      }

      setState(() {
        _bookedDates = bookedDates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: $e')),
      );
    }
  }

  bool _isDateBooked(DateTime date) {
    return _bookedDates.contains(DateTime(date.year, date.month, date.day));
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_isDateBooked(selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This date is already booked')),
      );
      return;
    }

    setState(() {
      if (_selectedStartDate == null) {
        _selectedStartDate = selectedDay;
      } else if (_selectedEndDate == null) {
        if (selectedDay.isAfter(_selectedStartDate!)) {
          _selectedEndDate = selectedDay;
        } else {
          _selectedEndDate = _selectedStartDate;
          _selectedStartDate = selectedDay;
        }
        widget.onDatesSelected?.call(_selectedStartDate, _selectedEndDate);
      } else {
        _selectedStartDate = selectedDay;
        _selectedEndDate = null;
      }
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${widget.roomType} Availability',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedStartDate, day) ||
                          (_selectedEndDate != null &&
                              (day.isAfter(_selectedStartDate!) &&
                                  day.isBefore(_selectedEndDate!))) ||
                          isSameDay(_selectedEndDate, day);
                    },
                    onDaySelected: _onDaySelected,
                    calendarStyle: CalendarStyle(
                      disabledTextStyle: const TextStyle(color: Colors.grey),
                      todayDecoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      rangeStartDecoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      rangeHighlightColor: Colors.blue.withOpacity(0.2),
                      outsideDaysVisible: false,
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        if (_isDateBooked(day)) {
                          return Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                      disabledBuilder: (context, day, focusedDay) {
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      },
                    ),
                    enabledDayPredicate: (day) {
                      // Disable past dates and booked dates
                      return day.isAfter(
                            DateTime.now().subtract(const Duration(days: 1)),
                          ) &&
                          !_isDateBooked(day);
                    },
                    rangeSelectionMode:
                        _selectedStartDate != null && _selectedEndDate == null
                            ? RangeSelectionMode.toggledOn
                            : RangeSelectionMode.toggledOff,
                  ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 12, color: Colors.red),
                SizedBox(width: 8),
                Text('Booked dates (is available)'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}