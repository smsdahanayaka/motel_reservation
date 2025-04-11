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

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    try {
      final current_user = _auth.currentUser;
      if (current_user == null) throw Exception('user not login');

      await _firestore.collection('users').doc(current_user.uid).delete();

      await current_user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile deleted successfully.')),
        );
      }

      // Navigate to login or welcome screen if needed
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete account failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Widget _buildBookingHistoryForm(Map<String, dynamic> userData) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('bookings')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No bookings found'));
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final data = booking.data() as Map<String, dynamic>;
            final checkIn = data['checkIn']?.toDate() ?? DateTime.now();
            final checkOut = data['checkOut']?.toDate() ?? DateTime.now();
            final createdAt = data['createdAt']?.toDate() ?? DateTime.now();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(data['roomType'] ?? 'No Room Type'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('dd MMM yyyy').format(checkIn)} - ${DateFormat('dd MMM yyyy').format(checkOut)}',
                    ),
                    Text('Status: ${data['status'] ?? 'Unknown'}'),
                    Text(
                      'Total: \$${data['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showBookingDetails(context, booking.id, data),
              ),
            );
          },
        );
      },
    );
  }

  void _showBookingDetails(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> bookingData,
  ) {
    final checkIn = bookingData['checkIn']?.toDate() ?? DateTime.now();
    final checkOut = bookingData['checkOut']?.toDate() ?? DateTime.now();
    final createdAt = bookingData['createdAt']?.toDate() ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bookingData['roomType'] ?? 'No Room Type',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                _buildDetailRow(
                  'Check-in',
                  DateFormat('dd MMM yyyy - hh:mm a').format(checkIn),
                ),
                _buildDetailRow(
                  'Check-out',
                  DateFormat('dd MMM yyyy - hh:mm a').format(checkOut),
                ),
                _buildDetailRow('Status', bookingData['status'] ?? 'Unknown'),
                _buildDetailRow(
                  'Total Price',
                  '\$${bookingData['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                ),
                _buildDetailRow(
                  'Booked on',
                  DateFormat('dd MMM yyyy - hh:mm a').format(createdAt),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (bookingData['status'] == 'Pending' ||
                        bookingData['status'] == 'Approved')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed:
                            () => _editBooking(context, bookingId, bookingData),
                        child: const Text('Edit'),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => _deleteBooking(context, bookingId),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _editBooking(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> bookingData,
  ) async {
    // Implement your edit booking logic here
    // You might want to navigate to a new screen or show a dialog for editing
    Navigator.pop(context); // Close the bottom sheet first

    // Example: Show a dialog with editable fields
    final roomTypeController = TextEditingController(
      text: bookingData['roomType'],
    );
    final checkInController = TextEditingController(
      text: DateFormat(
        'yyyy-MM-dd',
      ).format(bookingData['checkIn']?.toDate() ?? DateTime.now()),
    );
    final checkOutController = TextEditingController(
      text: DateFormat(
        'yyyy-MM-dd',
      ).format(bookingData['checkOut']?.toDate() ?? DateTime.now()),
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roomTypeController,
                  decoration: const InputDecoration(labelText: 'Room Type'),
                ),
                TextField(
                  controller: checkInController,
                  decoration: const InputDecoration(
                    labelText: 'Check-in Date (YYYY-MM-DD)',
                  ),
                ),
                TextField(
                  controller: checkOutController,
                  decoration: const InputDecoration(
                    labelText: 'Check-out Date (YYYY-MM-DD)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _firestore
                        .collection('bookings')
                        .doc(bookingId)
                        .update({
                          'roomType': roomTypeController.text,
                          'checkIn': DateTime.parse(checkInController.text),
                          'checkOut': DateTime.parse(checkOutController.text),
                          'updatedAt': DateTime.now(),
                        });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking updated successfully'),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating booking: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteBooking(BuildContext context, String bookingId) async {
    Navigator.pop(context); // Close the bottom sheet first

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Cancellation'),
            content: const Text(
              'Are you sure you want to cancel this booking?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('bookings').doc(bookingId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling booking: $e')),
          );
        }
      }
    }
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
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder:
                          (context) => Container(
                            padding: const EdgeInsets.all(16),
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: Column(
                              children: [
                                const Text(
                                  'Your Bookings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                Expanded(
                                  child: _buildBookingHistoryForm(userData),
                                ),
                              ],
                            ),
                          ),
                    );
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
                  Icons.delete,
                  'Delete Account',
                  color: Colors.red,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: Text('Confirm Deletion'),
                            content: Text(
                              'Are you sure you want to delete your account? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () =>
                                        Navigator.of(ctx).pop(), // Close dialog
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop(); // Close dialog first
                                  _deleteAccount(); // Then call the delete method
                                },
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                    );
                  },
                ),

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
