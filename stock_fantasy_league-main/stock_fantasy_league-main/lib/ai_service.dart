import 'package:google_generative_ai/google_generative_ai.dart';
import 'config.dart';

class AIService {
  static Future<String> getSummary(String newsTitle) async {
    try {
      final String cleanKey = Config.geminiApiKey.trim();

      if (cleanKey.isEmpty) {
        return "ERROR: Missing API Key in config.dart!";
      }

      final model = GenerativeModel(
        model: 'gemini-flash-latest', 
        apiKey: cleanKey,
      );
      
      final prompt = 'Summarize this financial news in 2-3 short sentences: "$newsTitle".';
      final content = [Content.text(prompt)];
      
      final response = await model.generateContent(content);
      
      return response.text ?? "No summary returned.";
      
    } catch (e) {
      print("AI Error Log: $e");
      return "ERROR: $e";
    }
  }
}