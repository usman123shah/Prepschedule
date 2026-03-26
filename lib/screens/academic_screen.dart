import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';

class AcademicScreen extends StatefulWidget {
  const AcademicScreen({super.key});

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> {
  final TextEditingController _promptController = TextEditingController();

  void _generate() {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter schedule details")));
      return;
    }

    // Just pass the raw prompt. The GeminiService has the robust system instruction.
    Provider.of<ScheduleProvider>(context, listen: false)
        .generateSchedule(_promptController.text, "Academic");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Academic Timetable")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Describe your academic requirements:", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            const Text(
              "Include details like:\n- Teachers & their courses\n- Room constraints\n- Class durations & breaks\n- Semester details",
              style: TextStyle(fontSize: 12, color: Colors.grey)
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "e.g., Prof. Smith teaches Math (3 credits) to Section A in Room 101. Dr. Jones teaches Physics to Section B. Avoid overlapping...",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Generate Timetable"),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<ScheduleProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                  if (provider.errorMessage != null) {
                    return SingleChildScrollView(
                      child: Text(
                        "Error: ${provider.errorMessage}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (provider.generatedJson != null) {
                     return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3))
                        ),
                        child: SingleChildScrollView(
                          child: Text(provider.generatedJson!, style: const TextStyle(fontFamily: 'Courier')),
                        ),
                     );
                  }
                  return const SizedBox();
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
