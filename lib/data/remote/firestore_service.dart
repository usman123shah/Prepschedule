import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionPath = 'schedules';

  // Save Schedule
  Future<String> saveSchedule(ScheduleModel schedule) async {
    if (schedule.userId == null) throw Exception("User ID is required to save schedule.");
    
    DocumentReference docRef = await _db.collection(_collectionPath).add({
      'user_id': schedule.userId,
      'title': schedule.title,
      'time': schedule.time,
      'date': schedule.date,
      'day': schedule.day,
      'category': schedule.category,
      'details': schedule.details,
      'created_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Get User Schedules
  Future<List<ScheduleModel>> getSchedules(String userId) async {
    // Note: Removed orderBy to avoid requiring a composite index in Firestore.
    // Sorting will be handled locally in Dart.
    QuerySnapshot query = await _db
        .collection(_collectionPath)
        .where('user_id', isEqualTo: userId)
        .get();

    List<ScheduleModel> results = query.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      // Map Firestore doc to ScheduleModel
      return ScheduleModel(
        id: null, 
        userId: data['user_id'],
        remoteId: doc.id, // Store Firestore doc ID
        title: data['title'],
        time: data['time'],
        date: data['date'],
        day: data['day'],
        category: data['category'],
        details: data['details'] ?? '',
        syncStatus: 1, // Already in Firestore
      );
    }).toList();

    // Local sorting by day
    results.sort((a, b) => a.day.compareTo(b.day));
    return results;
  }

  // Delete Schedule (Note: Would need a document ID for precise deletion)
  // For now, simple implementation
  Future<void> deleteSchedule(String userId, String title) async {
    QuerySnapshot query = await _db
        .collection(_collectionPath)
        .where('user_id', isEqualTo: userId)
        .where('title', isEqualTo: title)
        .get();
    
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }
}
