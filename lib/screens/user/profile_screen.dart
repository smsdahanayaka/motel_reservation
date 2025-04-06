// lib/screens/user/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/user.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/widgets/profile_header.dart';
import 'package:my_app/widgets/setting_tile.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late Future<AppUser> _userFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
  }

  Future<AppUser> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return AppUser.fromFirestore(doc);
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login', 
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    // TODO: Implement edit profile functionality
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Profile'),
          content: const Text('Profile editing functionality will be implemented here.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<AppUser>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeader(
                  name: user.name,
                  email: user.email,
                  joinDate: user.createdAt,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SettingTile(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: _editProfile,
                      ),
                      const SettingTile(
                        icon: Icons.history,
                        title: 'Booking History',
                      ),
                      const SettingTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                      ),
                      const SettingTile(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                      ),
                      const SettingTile(
                        icon: Icons.security_outlined,
                        title: 'Privacy Policy',
                      ),
                      const SizedBox(height: 16),
                      SettingTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        color: Colors.red,
                        onTap: _logout,
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}