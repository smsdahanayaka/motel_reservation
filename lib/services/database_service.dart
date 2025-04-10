// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/booking.dart';
import 'package:my_app/models/user.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _bookingsCollection =>
      _firestore.collection('bookings');

  // User Operations
  Future<void> createUserData({
    required String uid,
    required String name,
    required String email,
    bool isAdmin = false,
  }) async {
    await _usersCollection.doc(uid).set({
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.now(),
    });
  }

  Future<AppUser> getUserData(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    return AppUser.fromFirestore(doc);
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update(data);
  }

  // Booking Operations
  Future<void> createBooking({
    required String roomType,
    required DateTime checkIn,
    required DateTime checkOut,
    required double totalPrice,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _bookingsCollection.add({
      'userId': user.uid,
      'userEmail': user.email,
      'roomType': roomType,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': Timestamp.fromDate(checkOut),
      'totalPrice': totalPrice,
      'status': 'Pending', // Pending, Approved, Cancelled
      'createdAt': Timestamp.now(),
    });
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    final query =
        await _bookingsCollection
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

    return query.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }

  Future<List<Booking>> getAllBookings() async {
    final query =
        await _bookingsCollection.orderBy('createdAt', descending: true).get();

    return query.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }

  Future<List<Booking>> getBookingsByStatus(String status) async {
    final query =
        await _bookingsCollection
            .where('status', isEqualTo: status)
            .orderBy('createdAt', descending: true)
            .get();

    return query.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _bookingsCollection.doc(bookingId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'Cancelled');
  }

  // Room Availability Operations
  Future<bool> checkRoomAvailability({
    required String roomType,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final overlappingBookings =
        await _bookingsCollection
            .where('roomType', isEqualTo: roomType)
            .where('status', whereIn: ['Pending', 'Approved'])
            .get();

    for (final doc in overlappingBookings.docs) {
      final booking = Booking.fromFirestore(doc);
      if (checkIn.isBefore(booking.checkOut) &&
          checkOut.isAfter(booking.checkIn)) {
        return false; // Room is not available
      }
    }
    return true; // Room is available
  }

  // Streams for real-time updates
  Stream<List<Booking>> streamUserBookings(String userId) {
    return _bookingsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Booking>> streamAllBookings() {
    return _bookingsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList(),
        );
  }

  // Add this to your DatabaseService class
  // Add this to your DatabaseService class
  Future<List<Booking>> getBookingsForRoom(String roomType) async {
    final query =
        await _bookingsCollection
            .where('roomType', isEqualTo: roomType)
            .where(
              'status',
              whereIn: ['Pending', 'Approved'],
            ) // Only active bookings
            .get();

    return query.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }
}
