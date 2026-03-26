import 'package:flutter/material.dart';
import '../data/remote/gemini_service.dart';
import '../data/local/sqlite_service.dart';
import '../data/remote/firestore_service.dart';
import '../data/models/schedule_model.dart';
import 'auth_provider.dart';

class ScheduleProvider with ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final SqliteService _sqliteService = SqliteService();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<ScheduleModel> _schedules = [];
  List<ScheduleModel> get schedules => _schedules;
  
  bool _isLoading = false;
  String? _generatedJson;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get generatedJson => _generatedJson;
  String? get errorMessage => _errorMessage;

  Future<void> generateSchedule(String prompt, String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _generatedJson = await _geminiService.generateScheduleJson(prompt, category);
      // TODO: Save to SQLite / MySQL here
    } catch (e) {
      _errorMessage = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSchedules(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch from Firestore
      List<ScheduleModel> remoteSchedules = await _firestoreService.getSchedules(userId);
      
      // 2. Sync to SQLite (Upsert based on remoteId)
      for (var schedule in remoteSchedules) {
        await _sqliteService.insertSchedule(schedule);
      }
      
      // 3. Load from SQLite (Full list including maybe unsynced local ones)
      _schedules = await _sqliteService.getAllSchedules(userId);
    } catch (e) {
      print("Firestore Fetch Failed, falling back to SQLite: $e");
      // 4. Fallback to SQLite
      _schedules = await _sqliteService.getAllSchedules(userId);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveSchedule(ScheduleModel schedule, String userId) async {
    schedule.userId = userId;
    
    // 1. Save Locally (Initial)
    await _sqliteService.insertSchedule(schedule);
    
    // 2. Try Save Remotely (Firestore)
    try {
      String remoteId = await _firestoreService.saveSchedule(schedule);
      schedule.remoteId = remoteId;
      schedule.syncStatus = 1;
      
      // 3. Update local copy with remoteId and syncStatus
      await _sqliteService.insertSchedule(schedule); // Upserts because it has remoteId now
    } catch (e) {
      print("Remote Sync Failed: $e");
    }
    
    // Refresh list from local DB
    _schedules = await _sqliteService.getAllSchedules(userId);
    notifyListeners();
  }
}
