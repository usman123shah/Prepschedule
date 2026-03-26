import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/local/sqlite_service.dart';
import '../data/models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../providers/auth_provider.dart';

class SavedSchedulesScreen extends StatefulWidget {
  const SavedSchedulesScreen({super.key});

  @override
  State<SavedSchedulesScreen> createState() => _SavedSchedulesScreenState();
}

class _SavedSchedulesScreenState extends State<SavedSchedulesScreen> {
  final SqliteService _db = SqliteService();
  late Future<List<ScheduleModel>> _schedules;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<ScheduleProvider>(context, listen: false).fetchSchedules(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Schedules"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.schedules.isEmpty) {
            return const Center(child: Text("No saved schedules found."));
          }

          final schedules = provider.schedules;
          // Group by Day
          final grouped = <String, List<ScheduleModel>>{};
          for (var s in schedules) {
            grouped.putIfAbsent(s.day, () => []).add(s);
          }

          final days = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final list = grouped[day]!;

              return ExpansionTile(
                title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                initiallyExpanded: true,
                children: list.map((s) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(s.title),
                    subtitle: Text("${s.time} | ${s.category}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (s.syncStatus == 1) const Icon(Icons.cloud_done, color: Colors.green, size: 16),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                            if (user != null) {
                               // Assuming delete logic is added to provider or handled locally
                               // For now, call direct if provider doesn't have it yet
                               // await Provider.of<ScheduleProvider>(context, listen: false).deleteSchedule(s.id!);
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(s.title),
                          content: SingleChildScrollView(child: Text(s.details)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
                          ],
                        ),
                      );
                    },
                  ),
                )).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
