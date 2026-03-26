class ScheduleModel {
  int? id;
  String? userId; // Firebase User ID
  String? remoteId; // Firestore Document ID
  String title;
  String time;
  String date;
  String day;
  String category;
  String details;
  int syncStatus; // 0: Local only, 1: Synced to Firebase

  ScheduleModel({
    this.id,
    this.userId,
    this.remoteId,
    required this.title,
    required this.time,
    required this.date,
    required this.day,
    required this.category,
    this.details = '',
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'remote_id': remoteId,
      'title': title,
      'time': time,
      'date': date,
      'day': day,
      'category': category,
      'details': details,
      'sync_status': syncStatus,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'],
      userId: map['user_id'],
      remoteId: map['remote_id'],
      title: map['title'],
      time: map['time'],
      date: map['date'],
      day: map['day'],
      category: map['category'],
      details: map['details'] ?? '',
      syncStatus: map['sync_status'] ?? 0,
    );
  }
}
