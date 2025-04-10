import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/screens/auth/login_screen.dart';
import 'package:my_app/screens/auth/register_screen.dart';
import 'package:my_app/screens/user/booking_screen.dart';
import 'package:my_app/screens/user/profile_screen.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/widgets/availability_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String selectedRoomType = 'Standard Room';
  final GlobalKey _availabilityKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildNavBar(context),
            _buildHeroSection(context),
            _buildFeaturesSection(),
            _buildAvailabilitySection(),
            _buildTestimonials(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    // return Container(
    //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    //   decoration: BoxDecoration(
    //     color: Colors.white,
    //     boxShadow: [
    //       BoxShadow(
    //         color: Colors.grey.withOpacity(0.1),
    //         spreadRadius: 2,
    //         blurRadius: 10,
    //         offset: const Offset(0, 3),
    //       ),
    //     ],
    //   ),
    //   child: Row(
    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //     children: [
    //       const Text(
    //         'MotelReserve',
    //         style: TextStyle(
    //           fontSize: 24,
    //           fontWeight: FontWeight.bold,
    //           color: Colors.blue,
    //         ),
    //       ),
    //       Row(
    //         children: [
    //           _navItem('Home', context),
    //           _navItem('Rooms', context),
    //           _navItem('About', context),
    //           _navItem('Contact', context),
    //         ],
    //       ),
    //       Row(
    //         children: [
    //           TextButton(
    //             onPressed:
    //                 () => Navigator.push(
    //                   context,
    //                   MaterialPageRoute(
    //                     builder: (context) => const LoginScreen(),
    //                   ),
    //                 ),
    //             child: const Text('Login'),
    //           ),
    //           const SizedBox(width: 8),
    //           ElevatedButton(
    //             onPressed:
    //                 () => Navigator.push(
    //                   context,
    //                   MaterialPageRoute(
    //                     builder: (context) => const LoginScreen(),
    //                   ),
    //                 ),
    //             style: ElevatedButton.styleFrom(
    //               backgroundColor: Colors.blue,
    //               foregroundColor: Colors.white,
    //               shape: RoundedRectangleBorder(
    //                 borderRadius: BorderRadius.circular(8),
    //               ),
    //             ),
    //             child: const Text('Sign Up'),
    //           ),
    //         ],
    //       ),
    //     ],
    //   ),
    // );
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MotelReserve',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Row(
                children: [
                  _navItem('Home', context),
                  _navItem('Rooms', context),
                  _navItem('About', context),
                  _navItem('Contact', context),
                ],
              ),
              user != null
                  ? _buildUserProfile(context, user)
                  : _buildAuthButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
          child: const Text('Login'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Sign Up'),
        ),
      ],
    );
  }

  Widget _buildUserProfile(BuildContext context, User user) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Icon(Icons.error);
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen()),
            );
          },
          child: Row(
            children: [
              Text(
                userData['name']?.toString() ?? 'User',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                child: Text(
                  userData['name'] != null &&
                          (userData['name'] as String).isNotEmpty
                      ? (userData['name'] as String)[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navItem(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: () {},
        child: Text(
          title,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Your Perfect Stay',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Book comfortable motels at affordable prices across the country. Enjoy premium amenities and excellent service.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _scrollToAvailability(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Image.asset(
                'assets/images/hotel-hero.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToAvailability(BuildContext context) {
    final availabilitySection = context.findRenderObject() as RenderBox?;
    if (availabilitySection != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Why Choose Us',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _featureItem(
                Icons.location_city,
                'Prime Locations',
                'Our motels are located in convenient areas close to major attractions',
              ),
              _featureItem(
                Icons.wifi,
                'Free WiFi',
                'Stay connected with high-speed internet access',
              ),
              _featureItem(
                Icons.restaurant,
                'Breakfast Included',
                'Start your day with our complimentary breakfast',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String description) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      key: _availabilityKey,
      children: [
        const Text(
          'Check Availability',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Select a room type to see available dates',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
        const SizedBox(height: 32),
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: const [
                  Tab(text: 'Standard Room'),
                  Tab(text: 'Penthouse Suite'),
                ],
                labelColor: Colors.blue,
                indicatorColor: Colors.blue,
                onTap: (index) {
                  setState(() {
                    selectedRoomType =
                        index == 0 ? 'Standard Room' : 'Penthouse Suite';
                  });
                },
              ),
              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          AvailabilityCalendar(
                            roomType: 'Standard Room',
                            onDatesSelected: (start, end) {
                              setState(() {
                                selectedStartDate = start;
                                selectedEndDate = end;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          AvailabilityCalendar(
                            roomType: 'Penthouse Suite',
                            onDatesSelected: (start, end) {
                              setState(() {
                                selectedStartDate = start;
                                selectedEndDate = end;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (selectedStartDate != null && selectedEndDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Selected: ${DateFormat('MMM d, y').format(selectedStartDate!)} '
              '- ${DateFormat('MMM d, y').format(selectedEndDate!)}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            if (selectedStartDate != null && selectedEndDate != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BookingScreen(
                        roomType: selectedRoomType,
                        initialCheckIn: selectedStartDate,
                        initialCheckOut: selectedEndDate,
                      ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select check-in and check-out dates'),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Continue to Booking',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonials() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          const Text(
            'What Our Guests Say',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _testimonialItem(
                '"Excellent service and comfortable rooms. Will definitely come back!"',
                '- John D.',
              ),
              _testimonialItem(
                '"The best motel experience I\'ve had in years. Highly recommended!"',
                '- Sarah M.',
              ),
              _testimonialItem(
                '"Great value for money. Clean rooms and friendly staff."',
                '- Robert T.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _testimonialItem(String quote, String author) {
    return SizedBox(
      width: 300,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                quote,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      color: Colors.blue.shade900,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _footerColumn('Company', ['About Us', 'Careers', 'Press']),
              _footerColumn('Support', ['Contact', 'FAQ', 'Privacy Policy']),
              _footerColumn('Social', ['Facebook', 'Twitter', 'Instagram']),
            ],
          ),
          RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.white70),
              children: [
                const TextSpan(text: '© 2025 MotelReserve - '),
                TextSpan(
                  text: 'CodeLink',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(
                            Uri.parse('https://codelinkinternational.com/'),
                          );
                        },
                ),
                const TextSpan(text: '. All rights reserved.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  item,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}
