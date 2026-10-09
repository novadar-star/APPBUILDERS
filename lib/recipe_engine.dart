import 'dart:convert';
import 'package:http/http.dart' as http;

class LocalRecipeEngine {
  static const String _ollamaUrl = 'http://127.0.0.1:11434/api/generate'; // Ollama's local API endpoint
  static const String _modelName = 'llama3.2:latest'; // Matches your local download exactly!

  static Future<List<String>> compileRecipe(List<String> items) async {
    if (items.isEmpty) {
      return [
        '❌ No Ingredients Tracked',
        'Please point your camera closer to your food items or check your room lighting before trying again.',
      ];
    }

    // 🟩 Fixed: Backslash removed so Dart reads your 'Egg' variable perfectly!
    final String prompt = '''
You are a creative, resourceful college Dorm Chef AI. 
A student has scanned the following food items using their phone camera: \${items.join(", ")}.

Generate a simple, structured recipe they can easily cook in a dorm room using basic appliances (microwave, hot plate, or kettle).

Strict formatting rules:
Line 1: Start with an emoji and the Title of the recipe.
Line 2: Write a 1-sentence funny description.
Remaining lines: Provide numbered step-by-step cooking instructions.

Keep the total output concise (under 6 lines total). Do not include conversational intro or outro filler text.
''';

    try {
      final response = await http.post(
        Uri.parse(_ollamaUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _modelName,
          'prompt': prompt,
          'stream': false, 
        }),
      ).timeout(const Duration(seconds: 15)); 

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String generatedText = data['response'] ?? '';

        List<String> lines = generatedText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

        return lines.isNotEmpty ? lines : ['🥣 Fallback Dorm Mix', '1. Combine items and heat.'];
      } else {
        return ['⚠️ Local Server Error', 'Ollama responded with status code: \${response.statusCode}'];
      }
    } catch (e) {
      return [
        '🔌 Connect to Local LLM Engine',
        'Could not communicate with your local AI runtime.',
        '1. Ensure Ollama is running on your machine.',
        '2. Run `ollama run llama3.2` in your command line.',
        '3. If using Chrome, ensure web security is disabled flag is active.',
      ];
    }
  }
}
