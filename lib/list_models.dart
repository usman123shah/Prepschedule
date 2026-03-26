import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const apiKey = 'AIzaSyC_GPW1cRYuLCx_iCvKmtjL2J4ZYAyTJ80';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = (data['models'] as List).map((m) => m['name']).toList();
      print('Available Models:');
      for (var model in models) {
        if (model.toString().contains('gemini')) {
           print(model);
        }
      }
    } else {
      print('Error: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
