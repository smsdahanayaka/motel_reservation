// lib/widgets/availability_calendar.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/booking.dart';
import 'package:my_app/services/database_service.dart';

class AvailabilityCalendar extends StatefulWidget {
  final String roomType;
  final Function(DateTime, DateTime)? onDatesSelected;

  const AvailabilityCalendar({
    super.key,
    required this.roomType,
    this.onDatesSelected,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  Map<DateTime, List<Booking>> _bookedDates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedStartDate = DateTime.now();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final bookings = await DatabaseService().getBookingsForRoom(
        widget.roomType,
      );

      final bookedDates = <DateTime, List<Booking>>{};
      for (var booking in bookings) {
        final days = booking.checkOut.difference(booking.checkIn).inDays;
        for (int i = 0; i <= days; i++) {
          final date = DateTime(
            booking.checkIn.year,
            booking.checkIn.month,
            booking.checkIn.day,
          ).add(Duration(days: i));

          bookedDates.update(
            date,
            (existing) => [...existing, booking],
            ifAbsent: () => [booking],
          );
        }
      }

      setState(() {
        _bookedDates = bookedDates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading availability: ${e.toString()}')),
      );
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_bookedDates.containsKey(selectedDay)) return;

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
        if (widget.onDatesSelected != null) {
          widget.onDatesSelected!(_selectedStartDate!, _selectedEndDate!);
        }
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    disabledTextStyle: TextStyle(color: Colors.grey[400]),
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
                    markerDecoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (_bookedDates.containsKey(date)) {
                        return Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    disabledBuilder: (context, date, events) {
                      return Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      );
                    },
                  ),
                  enabledDayPredicate: (day) {
                    // Disable past dates and already booked dates
                    return day.isAfter(
                          DateTime.now().subtract(const Duration(days: 1)),
                        ) &&
                        !_bookedDates.containsKey(day);
                  },
                  rangeSelectionMode:
                      _selectedStartDate != null && _selectedEndDate == null
                          ? RangeSelectionMode.toggledOn
                          : RangeSelectionMode.toggledOff,
                ),
            const SizedBox(height: 16),
            if (_selectedStartDate != null && _selectedEndDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Selected: ${DateFormat('MMM d, y').format(_selectedStartDate!)} '
                  '- ${DateFormat('MMM d, y').format(_selectedEndDate!)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 12, color: Colors.red),
                SizedBox(width: 8),
                Text('Booked dates'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
