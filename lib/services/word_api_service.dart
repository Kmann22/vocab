import 'dart:convert';
import 'package:http/http.dart' as http;

class WordApiService {
  final String apiKey =
      'b72ce16e-9e88-468a-a750-4f9ece3c01c3'; // Replace with your API key
  final String baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  Future<Map<String, dynamic>?> fetchWordDetails(String word) async {
    final response = await http.get(Uri.parse('$baseUrl/$word'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final entry = data[0]; // Use the first entry
        final Map<String, dynamic> wordDetails = {
          'meaning': entry['meanings'][0]['definitions'][0]['definition'] ?? '',
          'sentence': entry['meanings'][0]['definitions'][0]['example'] ?? '',
          'pronunciation': entry['phonetic'] ?? '',
          'type': entry['meanings'][0]['partOfSpeech'] ?? '',
          'synonyms': entry['meanings'][0]['definitions'][0]['synonyms'] ?? [],
          'antonyms': entry['meanings'][0]['definitions'][0]['antonyms'] ?? [],
        };
        return wordDetails;
      }
    }
    return null;
  }
}
