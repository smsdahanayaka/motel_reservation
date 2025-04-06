// lib/screens/user/home_screen.dart
import 'package:flutter/material.dart';
import 'package:my_app/screens/user/booking_screen.dart';
import 'package:my_app/screens/user/profile_screen.dart';
import 'package:my_app/widgets/room_card.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            RoomCard(
              title: 'Standard Room',
              image: 'assets/standard_room.jpg',
              price: 'From \$17 / 5000 LKR per day',
              features: const [
                '1 day: \$17 / 5000 LKR',
                '2 days: \$30 / 9000 LKR',
                '3 days: \$45 / 13,500 LKR',
                '1 week: \$100 / 30,000 LKR',
              ],
              onBook: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingScreen(roomType: 'Standard Room'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            RoomCard(
              title: 'Penthouse Suite',
              image: 'assets/penthouse.jpg',
              price: 'From \$65 / 20,000 LKR per day',
              features: const [
                '1 day: \$65 / 20,000 LKR',
                '2 days: \$100 / 30,000 LKR',
                '3 days: \$135 / 40,000 LKR',
                '1 week: \$220 / 65,000 LKR',
                '1 month: \$750 / 225,000 LKR',
              ],
              onBook: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingScreen(roomType: 'Penthouse Suite'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}