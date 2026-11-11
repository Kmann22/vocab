import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Details looked up from the free dictionaryapi.dev service (no key needed).
class WordDetails {
  const WordDetails({
    required this.meaning,
    required this.type,
    this.sentence = '',
    this.pronunciation = '',
    this.synonyms = const [],
    this.antonyms = const [],
  });

  final String meaning;
  final String type;
  final String sentence;
  final String pronunciation;
  final List<String> synonyms;
  final List<String> antonyms;
}

class WordApiService {
  WordApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Returns null when the word isn't found or the network fails.
  Future<WordDetails?> lookup(String word) async {
    final query = word.trim().toLowerCase();
    if (query.isEmpty) return null;

    try {
      final uri = Uri.https('api.dictionaryapi.dev', '/api/v2/entries/en/$query');
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! List || data.isEmpty) return null;
      final entry = data.first as Map<String, dynamic>;

      var pronunciation = (entry['phonetic'] as String?) ?? '';
      if (pronunciation.isEmpty) {
        for (final p in (entry['phonetics'] as List? ?? const [])) {
          final text = (p as Map)['text'] as String?;
          if (text != null && text.isNotEmpty) {
            pronunciation = text;
            break;
          }
        }
      }

      final meanings = (entry['meanings'] as List? ?? const []).cast<Map<String, dynamic>>();
      if (meanings.isEmpty) return null;
      final first = meanings.first;
      final definitions = (first['definitions'] as List? ?? const []).cast<Map<String, dynamic>>();
      if (definitions.isEmpty) return null;

      // Prefer an example sentence from the same meaning, else any meaning.
      String sentence = '';
      for (final m in [first, ...meanings.skip(1)]) {
        for (final d in (m['definitions'] as List? ?? const []).cast<Map<String, dynamic>>()) {
          final ex = d['example'] as String?;
          if (ex != null && ex.isNotEmpty) {
            sentence = ex;
            break;
          }
        }
        if (sentence.isNotEmpty) break;
      }

      List<String> collect(String key) {
        final out = <String>{};
        for (final s in (first[key] as List? ?? const [])) {
          out.add(s.toString());
        }
        for (final d in definitions) {
          for (final s in (d[key] as List? ?? const [])) {
            out.add(s.toString());
          }
        }
        return out.take(8).toList();
      }

      return WordDetails(
        meaning: (definitions.first['definition'] as String?) ?? '',
        type: (first['partOfSpeech'] as String?) ?? '',
        sentence: sentence,
        pronunciation: pronunciation,
        synonyms: collect('synonyms'),
        antonyms: collect('antonyms'),
      );
    } catch (_) {
      return null;
    }
  }
}
