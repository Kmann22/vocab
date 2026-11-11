import 'package:cloud_firestore/cloud_firestore.dart';

/// One dictionary entry. Field names in Firestore are kept exactly as before
/// ('Word', 'Meaning', ...) so existing data keeps working.
class WordEntry {
  const WordEntry({
    this.id = '',
    required this.word,
    required this.type,
    required this.meaning,
    this.sentence = '',
    this.pronunciation = '',
    this.synonyms = const [],
    this.antonyms = const [],
    this.addedBy,
  });

  final String id;
  final String word;
  final String type;
  final String meaning;
  final String sentence;
  final String pronunciation;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? addedBy;

  String get initial => word.isEmpty ? '#' : word[0].toUpperCase();

  factory WordEntry.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};
    List<String> list(dynamic v) => v is List
        ? v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : const [];
    String str(dynamic v) => v == null ? '' : v.toString().trim();

    return WordEntry(
      id: doc.id,
      word: str(data['Word']),
      type: str(data['Type']),
      meaning: str(data['Meaning']),
      sentence: str(data['Sentence']),
      pronunciation: str(data['Pronunciation']),
      synonyms: list(data['Synonyms']),
      antonyms: list(data['Antonyms']),
      addedBy: data['AddedBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'Word': word,
        'Sentence': sentence,
        'Pronunciation': pronunciation,
        'Type': type,
        'Meaning': meaning,
        'Synonyms': synonyms,
        'Antonyms': antonyms,
        'AddedBy': addedBy ?? 'Anonymous',
        'Timestamp': FieldValue.serverTimestamp(),
      };

  /// Text used when sharing a word.
  String toShareText() {
    final b = StringBuffer('📚 $word');
    if (pronunciation.isNotEmpty) b.write('  $pronunciation');
    if (type.isNotEmpty) b.write('  ($type)');
    b.write('\n\n$meaning');
    if (sentence.isNotEmpty) b.write('\n\n“$sentence”');
    if (synonyms.isNotEmpty) b.write('\n\nSynonyms: ${synonyms.join(', ')}');
    if (antonyms.isNotEmpty) b.write('\nAntonyms: ${antonyms.join(', ')}');
    b.write('\n\nShared from WordWiser');
    return b.toString();
  }
}
