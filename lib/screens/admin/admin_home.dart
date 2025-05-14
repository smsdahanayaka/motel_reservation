import 'package:flutter/material.dart';
import 'package:my_app/screens/admin/bookings_screen.dart';
import 'package:my_app/screens/admin/users_screen.dart';
import 'package:my_app/services/auth_service.dart'; // Ensure this is the correct path

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  bool _isLoading = false;

  final List<Widget> _pages = [
    const AdminBookingsScreen(),
    const AdminUsersScreen(),
  ];

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Master data'),
        ],
      ),
    );
  }
}
