import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReservationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new reservation in Firestore
  static Future<String> createReservation({
    required String name,
    required String phone,
    String? email,
    required DateTime date,
    required String time,
    required int guests,
    String? specialRequests,
  }) async {
    try {
      final user = _auth.currentUser;

      // Generate a readable reservation ID (e.g., TN240115001)
      final dateStr = DateFormat('yyMMdd').format(date);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final shortId = timestamp.toString().substring(
        timestamp.toString().length - 3,
      );
      final readableId = 'TN$dateStr$shortId';

      final reservationData = {
        'reservationId': readableId,
        'customerInfo': {'name': name, 'phone': phone, 'email': email},
        'reservationDetails': {
          'date': DateFormat('yyyy-MM-dd').format(date),
          'time': time,
          'guests': guests,
          'specialRequests': specialRequests,
        },
        'status': 'pending', // pending, confirmed, completed, cancelled
        'restaurantInfo': {
          'tableNumber': null,
          'estimatedDuration': 120, // minutes
          'notes': null,
        },
        'timestamps': {
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'confirmedAt': null,
        },
        'metadata': {
          'source': 'mobile_app',
          'userId': user?.uid,
          'isGuest': user?.isAnonymous ?? true,
        },
      };

      await _firestore.collection('reservations').add(reservationData);

      return readableId;
    } catch (e) {
      throw Exception('Failed to create reservation: $e');
    }
  }

  /// Get reservations for the current user
  static Future<List<Map<String, dynamic>>> getUserReservations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('reservations')
          .where('metadata.userId', isEqualTo: user.uid)
          .orderBy('timestamps.createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch reservations: $e');
    }
  }

  /// Cancel a reservation
  static Future<void> cancelReservation(String docId) async {
    try {
      await _firestore.collection('reservations').doc(docId).update({
        'status': 'cancelled',
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
        'timestamps.cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel reservation: $e');
    }
  }

  /// Update reservation status (for admin use)
  static Future<void> updateReservationStatus(
    String docId,
    String status, {
    String? tableNumber,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'confirmed') {
        updateData['timestamps.confirmedAt'] = FieldValue.serverTimestamp();
      }

      if (tableNumber != null) {
        updateData['restaurantInfo.tableNumber'] = tableNumber;
      }

      if (notes != null) {
        updateData['restaurantInfo.notes'] = notes;
      }

      await _firestore.collection('reservations').doc(docId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update reservation: $e');
    }
  }

  /// Check if a time slot is available (basic check)
  static Future<bool> isTimeSlotAvailable(
    DateTime date,
    String time,
    int guests,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final querySnapshot = await _firestore
          .collection('reservations')
          .where('reservationDetails.date', isEqualTo: dateStr)
          .where('reservationDetails.time', isEqualTo: time)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      // Simple logic: limit to 5 tables per time slot
      // You can make this more sophisticated based on your restaurant capacity
      final totalGuests = querySnapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['reservationDetails']['guests'] as int),
      );

      // Assuming restaurant capacity of 50 guests per time slot
      return (totalGuests + guests) <= 50;
    } catch (e) {
      return true; // If check fails, allow booking (you can change this logic)
    }
  }

  /// Get all reservations for today (for restaurant staff)
  static Stream<List<Map<String, dynamic>>> getTodayReservations() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return _firestore
        .collection('reservations')
        .where('reservationDetails.date', isEqualTo: today)
        .orderBy('reservationDetails.time')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Format reservation data for printing/notifications
  static Map<String, dynamic> formatForPrinter(
    Map<String, dynamic> reservation,
  ) {
    return {
      'type': 'RESERVATION',
      'id': reservation['reservationId'],
      'customer': {
        'name': reservation['customerInfo']['name'],
        'phone': reservation['customerInfo']['phone'],
        'email': reservation['customerInfo']['email'],
      },
      'details': {
        'date': reservation['reservationDetails']['date'],
        'time': reservation['reservationDetails']['time'],
        'guests': reservation['reservationDetails']['guests'],
        'specialRequests': reservation['reservationDetails']['specialRequests'],
      },
      'status': reservation['status'],
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
