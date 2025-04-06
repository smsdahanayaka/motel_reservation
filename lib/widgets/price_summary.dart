import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceSummary extends StatelessWidget {
  final String roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final double price;
  final double lkrRate = 300; // Example conversion rate

  const PriceSummary({
    super.key,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final days = checkOut.difference(checkIn).inDays;
    final lkrPrice = price * lkrRate;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Room Type', roomType),
            _buildSummaryRow('Check-in', DateFormat('MMM dd, yyyy').format(checkIn)),
            _buildSummaryRow('Check-out', DateFormat('MMM dd, yyyy').format(checkOut)),
            _buildSummaryRow('Duration', '$days ${days == 1 ? 'day' : 'days'}'),
            const Divider(height: 32),
            _buildSummaryRow('Total (USD)', '\$${price.toStringAsFixed(2)}', isBold: true),
            _buildSummaryRow('Total (LKR)', '${lkrPrice.toStringAsFixed(0)} LKR', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: isBold
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }
}