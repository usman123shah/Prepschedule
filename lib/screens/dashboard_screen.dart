import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import 'chat_schedule_screen.dart';
import 'saved_schedules_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger background sync on dashboard open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<ScheduleProvider>(context, listen: false).fetchSchedules(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(context, "Academic", Icons.menu_book, 
              (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ChatScheduleScreen(category: "Academic")))),
              
            _buildCard(context, "Nutrition", Icons.restaurant_menu, 
              (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ChatScheduleScreen(category: "Nutrition")))),
              
            _buildCard(context, "Business", Icons.business_center, 
              (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ChatScheduleScreen(category: "Business")))),
              
            _buildCard(context, "Student", Icons.backpack, 
               (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ChatScheduleScreen(category: "Student")))),
               
            _buildCard(context, "Personal", Icons.person, 
               (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ChatScheduleScreen(category: "Personal")))),
               
            _buildCard(context, "History", Icons.history, 
               (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SavedSchedulesScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Function(BuildContext) onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => onTap(context),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.deepPurple),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
