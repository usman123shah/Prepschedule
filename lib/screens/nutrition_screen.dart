import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final TextEditingController _preferenceController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();

  void _generate() {
    String prompt = "Create a diet plan.\nPreferences: ${_preferenceController.text}\nAllergies/Restrictions: ${_allergiesController.text}\nEnsure no clashes in meal timing.";
    
    Provider.of<ScheduleProvider>(context, listen: false)
        .generateSchedule(prompt, "Nutrition");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nutrition Plan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _preferenceController,
              decoration: const InputDecoration(labelText: "Diet Preference (e.g. Vegan, Keto)", prefixIcon: Icon(Icons.restaurant)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _allergiesController,
              decoration: const InputDecoration(labelText: "Allergies / Restrictions"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generate,
                child: const Text("Generate Diet Plan"),
              ),
            ),
            const SizedBox(height: 20),
             Expanded(
              child: Consumer<ScheduleProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                  if (provider.generatedJson != null) {
                     return SingleChildScrollView(
                       child: Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.green[50],
                          child: Text(provider.generatedJson!),
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
