import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/schedule_provider.dart';
import '../providers/auth_provider.dart';
import '../data/models/schedule_model.dart';
import 'package:intl/intl.dart';
import 'saved_schedules_screen.dart';

class ChatScheduleScreen extends StatefulWidget {
  final String category;
  const ChatScheduleScreen({super.key, required this.category});

  @override
  State<ChatScheduleScreen> createState() => _ChatScheduleScreenState();
}

class _ChatScheduleScreenState extends State<ChatScheduleScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = []; // {'role': 'user' | 'ai', 'content': ''}
  bool _isAILoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
      _isAILoading = true;
    });

    try {
      final provider = Provider.of<ScheduleProvider>(context, listen: false);
      await provider.generateSchedule(text, widget.category);
      
      final error = provider.errorMessage;
      final response = provider.generatedJson;

      setState(() {
        _isAILoading = false;
        if (error != null) {
           _messages.add({'role': 'ai', 'content': 'Error: $error'});
        } else if (response != null) {
           _messages.add({'role': 'ai', 'content': response});
        }
      });
    } catch (e) {
       setState(() {
         _isAILoading = false;
         _messages.add({'role': 'ai', 'content': 'Error: $e'});
       });
    }
  }

  Widget _buildAIContent(String content) {
    try {
      final data = jsonDecode(content);
      if (data is Map && data.containsKey('type')) {
        if (data['type'] == 'list') {
          final items = data['data'] as List;
          return Column(
            children: items.map((item) => _buildScheduleCard(item)).toList(),
          );
        } else if (data['type'] == 'table') {
          final items = data['data'] as List;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurple.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade50),
                  dataRowColor: MaterialStateProperty.all(Colors.white),
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  border: TableBorder.all(color: Colors.deepPurple.shade100, width: 0.5),
                  columns: const [
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Mon')),
                    DataColumn(label: Text('Tue')),
                    DataColumn(label: Text('Wed')),
                    DataColumn(label: Text('Thu')),
                    DataColumn(label: Text('Fri')),
                  ],
                  rows: items.map((item) => DataRow(cells: [
                    DataCell(Text(item['time']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(item['monday']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(item['tuesday']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(item['wednesday']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(item['thursday']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(item['friday']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                  ])).toList(),
                ),
              ),
            ),
          );
        }
      }
    } catch (_) {
      // Not JSON, return regular text
    }
    return Text(content);
  }

  Widget _buildScheduleCard(Map<String, dynamic> item) {
    final title = item['title'] ?? 'No Title';
    final time = item['time'] ?? '';
    final day = item['day'] ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Colors.blueGrey, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text("$day at $time", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.add_task, color: Colors.deepPurple),
          onPressed: () => _showEditDialog(jsonEncode(item)),
        ),
      ),
    );
  }

  void _showEditDialog(String aiContent) {
    String initialTitle = "${widget.category} Schedule";
    String initialTime = "09:00 AM - 10:00 AM";
    String initialDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String initialDay = DateFormat('EEEE').format(DateTime.now());
    String initialDetails = aiContent;

    try {
      final data = jsonDecode(aiContent);
      if (data is Map) {
        initialTitle = data['title'] ?? initialTitle;
        initialTime = data['time'] ?? initialTime;
        initialDay = data['day'] ?? initialDay;
      }
    } catch (_) {}

    final titleController = TextEditingController(text: initialTitle);
    final timeController = TextEditingController(text: initialTime);
    final dateController = TextEditingController(text: initialDate);
    final dayController = TextEditingController(text: initialDay);
    final detailsController = TextEditingController(text: initialDetails);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit & Save Schedule"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Label Name")),
              TextField(controller: timeController, decoration: const InputDecoration(labelText: "Time")),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: "Date")),
              TextField(controller: dayController, decoration: const InputDecoration(labelText: "Day")),
              TextField(
                controller: detailsController, 
                decoration: const InputDecoration(labelText: "Full Schedule Details"),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final userId = authProvider.currentUser?.id;

              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to save schedules.")));
                return;
              }

              final newSchedule = ScheduleModel(
                userId: userId,
                title: titleController.text,
                time: timeController.text,
                date: dateController.text,
                day: dayController.text,
                category: widget.category,
                details: detailsController.text,
              );
              await Provider.of<ScheduleProvider>(context, listen: false).saveSchedule(newSchedule, userId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to SQLite & Firebase!")));
            }, 
            child: const Text("Save & Sync"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.category} Chat"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedSchedulesScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isAILoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.deepPurple[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isUser ? Text(msg['content']!) : _buildAIContent(msg['content']!),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type your schedule request...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
