import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';

class GenericScheduleScreen extends StatefulWidget {
  final String category;
  const GenericScheduleScreen({super.key, required this.category});

  @override
  State<GenericScheduleScreen> createState() => _GenericScheduleScreenState();
}

class _GenericScheduleScreenState extends State<GenericScheduleScreen> {
  final TextEditingController _promptController = TextEditingController();

  void _generate() {
    if (_promptController.text.isEmpty) return;
    
    Provider.of<ScheduleProvider>(context, listen: false)
        .generateSchedule(_promptController.text, widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.category} Schedule")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Describe your day to generate a schedule:"),
            const SizedBox(height: 10),
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "e.g., I have a meeting at 10am and gym at 5pm...",
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generate,
                child: const Text("Generate Schedule"),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<ScheduleProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.errorMessage != null) {
                    return Text("Error: ${provider.errorMessage}", style: const TextStyle(color: Colors.red));
                  }
                  if (provider.generatedJson != null) {
                    return SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey[200],
                        child: Text(provider.generatedJson!), // Showing Raw JSON as requested
                      ),
                    );
                  }
                  return const Center(child: Text("No schedule generated yet."));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
