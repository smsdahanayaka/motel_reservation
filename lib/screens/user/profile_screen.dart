import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_app/services/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<Map<String, dynamic>> _userFuture;
  bool _isLoading = false;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) throw Exception('User data not found');

    return {
      'name': doc.data()?['name'] ?? 'No Name',
      // 'email': user.email ?? 'No Email',
      'email': doc.data()?['email'] ?? 'No Email',
      'createdAt': doc.data()?['createdAt']?.toDate() ?? DateTime.now(),
      'isAdmin': doc.data()?['isAdmin'] ?? false,
    };
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
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

  Future<void> _editProfile() async {
    final userData = await _userFuture;
    _nameController.text = userData['name'];
    _emailController.text = userData['email'];

    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      print(_emailController.text);
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text,
        'email': _emailController.text,
        'updatedAt': DateTime.now(),
      });

      setState(() {
        _isEditing = false;
        _userFuture = _fetchUserData(); // Refresh data
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            userData['name'].toString().isNotEmpty
                ? userData['name'][0].toUpperCase()
                : 'U',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          userData['name'],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          userData['email'],
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Text(
          'Member since ${DateFormat('MMM yyyy').format(userData['createdAt'])}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildEditForm(Map<String, dynamic> userData) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
            ),
            validator: (value1) {
              if (value1 == null || value1.isEmpty) {
                return "Please enter your mail";
              }
              return null;
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit), onPressed: _editProfile),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () => setState(() {
                          _userFuture = _fetchUserData();
                        }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_isEditing)
                  _buildEditForm(userData)
                else
                  _buildProfileHeader(userData),

                const SizedBox(height: 30),
                const Divider(),

                _buildSettingTile(
                  Icons.history,
                  'Booking History',
                  onTap: () {
                    // Navigate to booking history
                  },
                ),
                _buildSettingTile(
                  Icons.notifications_outlined,
                  'Notifications',
                  onTap: () {
                    // Navigate to notifications
                  },
                ),
                _buildSettingTile(
                  Icons.help_outline,
                  'Help Center',
                  onTap: () {
                    // Navigate to help center
                  },
                ),
                _buildSettingTile(
                  Icons.security_outlined,
                  'Privacy Policy',
                  onTap: () {
                    // Navigate to privacy policy
                  },
                ),

                const Divider(),
                const SizedBox(height: 10),

                _buildSettingTile(
                  Icons.logout,
                  'Logout',
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
          );
        },
      ),
    );
  }
}
