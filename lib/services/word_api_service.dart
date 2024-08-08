import 'dart:convert';
import 'package:http/http.dart' as http;

class WordApiService {
  final String apiKey =
      'b72ce16e-9e88-468a-a750-4f9ece3c01c3'; // Replace with your API key
  final String baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  Future<Map<String, dynamic>?> fetchWordDetails(String word) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$word'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.isNotEmpty) {
          final entry = data[0];

          // Accessing fields with null safety and defaults
          final phonetic = entry['phonetic'] ?? '';
          final phonetics = (entry['phonetics'] as List<dynamic>? ?? []);
          final audio = phonetics.isNotEmpty ? phonetics[0]['audio'] ?? '' : '';

          final meanings = entry['meanings'] as List<dynamic>? ?? [];
          final firstMeaning = meanings.isNotEmpty ? meanings[0] : {};
          final definitions =
              firstMeaning['definitions'] as List<dynamic>? ?? [];
          final firstDefinition = definitions.isNotEmpty ? definitions[0] : {};

          final wordDetails = {
            'meaning':
                firstDefinition['definition'] ?? 'No definition available',
            'sentence':
                firstDefinition['example'] ?? 'No example sentence available',
            'pronunciation':
                phonetic.isNotEmpty ? phonetic : 'No pronunciation available',
            'audio': audio.isNotEmpty ? audio : 'No audio available',
            'type': firstMeaning['partOfSpeech'] ?? 'No type available',
            'synonyms': (firstMeaning['synonyms'] as List<dynamic>?)
                    ?.map((s) => s.toString())
                    .toList() ??
                [],
            'antonyms': (firstMeaning['antonyms'] as List<dynamic>?)
                    ?.map((a) => a.toString())
                    .toList() ??
                [],
          };

          return wordDetails;
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching word details: $e');
    }
    return null;
  }
}
