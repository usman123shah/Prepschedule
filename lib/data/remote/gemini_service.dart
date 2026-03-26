import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // TODO: Replace with your actual Gemini API Key
  static const String _apiKey = 'AIzaSyAglqQs_QkjMG8FM6ttNkiWc0EeYeZady8';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String> generateScheduleJson(String userPrompt, String category) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');
    
    // Category-specific instructions for structured JSON output
    String systemInstruction = "";
    if (category == "Academic" || category == "Nutrition") {
      systemInstruction = "You are a professional scheduler. Return a JSON object for a '$category' plan. Use type: 'table'. The data should be a list of objects with fields: time, monday, tuesday, wednesday, thursday, friday. Return ONLY JSON. Format: { 'type': 'table', 'data': [ { 'time': '', 'monday': '', ... } ] }";
    } else {
      systemInstruction = "You are a professional scheduler. Return a JSON object for a '$category' schedule. Use type: 'list'. The data should be a list of objects with fields: title, time, day. Return ONLY JSON. Format: { 'type': 'list', 'data': [ { 'title': '', 'time': '', 'day': '' } ] }";
    }

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "contents": [{
        "parts": [{
          "text": "$systemInstruction\nUser Request: $userPrompt"
        }]
      }]
    });

    try {
      final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();
        return text;
      } else {
        throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate schedule: $e');
    }
  }
}
