import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../models/word_entry.dart';
import 'words.dart';

/// A word of the day with a short, original message.
class DailyWord {
  const DailyWord({
    required this.word,
    required this.type,
    required this.meaning,
    required this.message,
    this.sentence = '',
    this.entryId = '',
    this.fromAi = false,
  });

  final String word;
  final String type;
  final String meaning;
  final String message;
  final String sentence;

  /// ID of the word in the shared dictionary ('' for a built-in backup word).
  final String entryId;
  final bool fromAi;

  bool get inDictionary => entryId.isNotEmpty;

  factory DailyWord.fromMap(Map<String, dynamic> m) => DailyWord(
        word: (m['word'] ?? '').toString(),
        type: (m['type'] ?? '').toString(),
        meaning: (m['meaning'] ?? '').toString(),
        message: (m['message'] ?? '').toString(),
        sentence: (m['sentence'] ?? '').toString(),
        entryId: (m['entryId'] ?? '').toString(),
        fromAi: m['fromAi'] == true,
      );

  Map<String, dynamic> toMap() => {
        'word': word,
        'type': type,
        'meaning': meaning,
        'message': message,
        'sentence': sentence,
        'entryId': entryId,
        'fromAi': fromAi,
        'createdAt': FieldValue.serverTimestamp(),
      };

  WordEntry toEntry() => WordEntry(
        id: entryId,
        word: word,
        type: type,
        meaning: meaning,
        sentence: sentence,
      );

  DailyWord withMessage(String newMessage, {required bool ai}) => DailyWord(
        word: word,
        type: type,
        meaning: meaning,
        sentence: sentence,
        entryId: entryId,
        message: newMessage,
        fromAi: ai,
      );

  String toShareText() =>
      '✨ Word of the day: $word${type.isEmpty ? '' : ' ($type)'}\n'
      '$meaning\n\n$message\n\nShared from WordWiser';
}

/// Gets today's word of the day.
///
/// 1. The word is picked from YOUR shared dictionary using today's date, so
///    everyone sees the same word all day.
/// 2. Gemini writes a short, original message using that word and meaning.
/// 3. The result is saved in Firestore (DailyWord/{yyyy-mm-dd}) so the AI is
///    only asked once per day — well inside the free tier.
///
/// If the AI isn't available, a handwritten template message is used instead.
/// If the dictionary is empty, a word from the built-in list is used.
class DailyWordService {
  DailyWordService({FirebaseFirestore? db, WordRepository? repo})
      : _db = db ?? FirebaseFirestore.instance,
        _repo = repo ?? WordRepository();

  /// Gemini model used for the daily message. Change it here if Google
  /// retires this model (see firebase.google.com/docs/ai-logic/models).
  static const modelName = 'gemini-3.5-flash-lite';

  final FirebaseFirestore _db;
  final WordRepository _repo;

  static String? _cachedId;
  static Future<DailyWord>? _cached;

  CollectionReference<Map<String, dynamic>> get _days => _db.collection('DailyWord');

  static String dateId(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _seed(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  /// Today's word, fetched at most once per app session.
  Future<DailyWord> today() {
    final id = dateId(DateTime.now());
    if (_cachedId != id || _cached == null) {
      _cachedId = id;
      _cached = _load(id);
    }
    return _cached!;
  }

  Future<DailyWord> _load(String id) async {
    final now = DateTime.now();
    final ref = _days.doc(id);

    // 1. Someone already made today's word.
    try {
      final snap = await ref.get();
      if (snap.exists && snap.data() != null) return DailyWord.fromMap(snap.data()!);
    } catch (_) {
      // Offline or rules not deployed — carry on and build one locally.
    }

    // 2. Pick today's word from the dictionary.
    List<WordEntry> words;
    try {
      words = await _repo.fetchAll();
    } catch (_) {
      words = const [];
    }
    if (words.isEmpty) return fallbackFor(now);

    final entry = pickForDate(words, now, recent: await _recentWords());
    final base = DailyWord(
      word: entry.word,
      type: entry.type,
      meaning: entry.meaning,
      sentence: entry.sentence,
      entryId: entry.id,
      message: templateMessage(entry.word, entry.meaning, now),
    );

    // 3. Ask Gemini for a message. Keep the template if it fails.
    String? aiMessage;
    try {
      aiMessage = await _writeMessage(entry);
    } catch (_) {
      aiMessage = null;
    }
    if (aiMessage == null) return base;
    final result = base.withMessage(aiMessage, ai: true);

    // 4. Save it, unless someone else saved one a moment earlier.
    try {
      return await _db.runTransaction<DailyWord>((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists && snap.data() != null) return DailyWord.fromMap(snap.data()!);
        tx.set(ref, result.toMap());
        return result;
      });
    } catch (_) {
      return result;
    }
  }

  Future<List<String>> _recentWords() async {
    try {
      final snap = await _days.orderBy(FieldPath.documentId, descending: true).limit(30).get();
      return snap.docs.map((d) => (d.data()['word'] ?? '').toString()).where((w) => w.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Picks the same word for everyone on a given date, skipping words used
  /// recently when the dictionary is big enough.
  static WordEntry pickForDate(List<WordEntry> words, DateTime date, {List<String> recent = const []}) {
    final sorted = [...words]..sort((a, b) => a.id.compareTo(b.id));
    final used = recent.map((w) => w.toLowerCase()).toSet();
    final fresh = sorted.where((w) => !used.contains(w.word.toLowerCase())).toList();
    final pool = fresh.isNotEmpty ? fresh : sorted;
    return pool[Random(_seed(date)).nextInt(pool.length)];
  }

  Future<String?> _writeMessage(WordEntry entry) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: modelName,
      generationConfig: GenerationConfig(temperature: 0.9),
    );

    final prompt = '''
You write the "word of the day" message for a vocabulary-learning app.

Word: ${entry.word}
${entry.type.isEmpty ? '' : 'Type: ${entry.type}\n'}Meaning: ${entry.meaning}
${entry.sentence.isEmpty ? '' : 'Example: ${entry.sentence}\n'}
Write ONE short, warm, uplifting message or saying (1–2 sentences, under 35 words)
that uses the word "${entry.word}" naturally and in a way that matches its meaning.
It must be original: do not quote or credit any real person or book.
Reply with the message only — no quotation marks, no title, no emojis.
''';

    final response = await model.generateContent([Content.text(prompt)]);
    return cleanMessage(response.text ?? '', entry.word);
  }

  /// Tidies the AI's reply. Returns null if it's unusable (empty, too long,
  /// or doesn't actually use the word).
  static String? cleanMessage(String text, String word) {
    var m = text.trim();
    m = m.replaceAll(RegExp(r'^```[a-z]*\s*|\s*```$'), '');
    m = m.replaceAll(RegExp(r'''^["“”'\s]+|["“”'\s]+$'''), '');
    m = m.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (m.isEmpty || m.length > 280) return null;
    if (!m.toLowerCase().contains(word.toLowerCase())) return null;
    return m;
  }

  /// Handwritten messages used when the AI isn't available.
  static String templateMessage(String word, String meaning, DateTime date) {
    final m = meaning.isEmpty ? '' : meaning[0].toLowerCase() + meaning.substring(1);
    final templates = [
      'Today’s word is $word — $m. Find a moment to use it before the day is done.',
      'Carry $word with you today. Words become yours the moment you use them.',
      'Here’s a small gift for your vocabulary: $word. Try it in a sentence today!',
      '$word: $m. Notice where it fits in your day — you might be surprised.',
      'One word can brighten a conversation. Today, let it be $word.',
    ];
    return templates[Random(_seed(date) + 7).nextInt(templates.length)];
  }

  /// Built-in backup words, picked by date, so the card always has something.
  static DailyWord fallbackFor(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final w = _fallbackWords[Random(seed).nextInt(_fallbackWords.length)];
    return DailyWord(word: w[0], type: w[1], meaning: w[2], message: w[3]);
  }

  static const _fallbackWords = [
    ['Serendipity', 'noun', 'Finding something good without looking for it',
        'Leave a little room in your day for serendipity — the best surprises rarely make appointments.'],
    ['Luminous', 'adjective', 'Full of light; shining brightly',
        'You don’t have to be loud to be luminous. Quiet kindness lights up a room too.'],
    ['Resilience', 'noun', 'The ability to recover quickly from difficulties',
        'Every time you try again, your resilience grows a little stronger. Keep going.'],
    ['Ephemeral', 'adjective', 'Lasting for a very short time',
        'Sunsets are ephemeral, which is exactly why they are worth stopping for.'],
    ['Halcyon', 'adjective', 'Calm, peaceful and happy',
        'May today hold a halcyon moment — a cup of tea, a deep breath, a little peace.'],
    ['Mellifluous', 'adjective', 'Sweet and smooth to hear',
        'Speak kindly to yourself today; let your inner voice be mellifluous, not harsh.'],
    ['Sonder', 'noun', 'Realising every stranger has a life as rich as your own',
        'Feel a little sonder today: everyone you pass is the hero of their own story.'],
    ['Petrichor', 'noun', 'The pleasant smell of earth after rain',
        'Even grey days bring petrichor. Something good often follows the rain.'],
    ['Eunoia', 'noun', 'Beautiful thinking; goodwill towards others',
        'Start the day with eunoia — kind thoughts have a way of becoming kind actions.'],
    ['Ineffable', 'adjective', 'Too great to be described in words',
        'Some joys are ineffable. Notice them anyway, even if you can’t name them.'],
    ['Solace', 'noun', 'Comfort in a time of sadness',
        'Find solace in small things today: a song, a friend, a page of a good book.'],
    ['Aurora', 'noun', 'The dawn; a natural light display in the sky',
        'Every morning is an aurora of possibility. What will you learn today?'],
    ['Tenacity', 'noun', 'Determination to keep going',
        'Tenacity is learning one more word when you’d rather stop. You’ve got this.'],
    ['Euphoria', 'noun', 'A feeling of great happiness',
        'Learning something new can spark a small euphoria. Chase that feeling today.'],
    ['Wanderlust', 'noun', 'A strong desire to travel and explore',
        'Let your wanderlust guide you, even if today’s journey is only through new words.'],
    ['Kindred', 'adjective', 'Similar in nature or feeling',
        'Somewhere, a kindred spirit is learning this word too. You’re never learning alone.'],
    ['Radiant', 'adjective', 'Bright and full of happiness',
        'A radiant smile costs nothing and can change someone’s whole day.'],
    ['Quintessential', 'adjective', 'The most perfect example of something',
        'Be the quintessential version of you — curious, kind and always learning.'],
    ['Effervescent', 'adjective', 'Bubbly, lively and enthusiastic',
        'Bring a little effervescent energy to whatever you do today.'],
    ['Gratitude', 'noun', 'The feeling of being thankful',
        'Name three things you feel gratitude for. Watch how the day softens.'],
    ['Reverie', 'noun', 'A pleasant daydream',
        'Allow yourself a short reverie today; great ideas often begin as daydreams.'],
    ['Sanguine', 'adjective', 'Hopeful and optimistic',
        'Stay sanguine — the word you struggle with today will be easy tomorrow.'],
    ['Epiphany', 'noun', 'A sudden moment of understanding',
        'Keep asking questions; your next epiphany might be one answer away.'],
    ['Cherish', 'verb', 'To hold something dear and protect it',
        'Cherish the people who make you laugh. They are rarer than gold.'],
    ['Bliss', 'noun', 'Perfect happiness',
        'Bliss is often simple: a quiet morning, a warm drink, a new idea.'],
    ['Lucid', 'adjective', 'Clear and easy to understand',
        'May your thoughts be lucid and your words be kind today.'],
    ['Vivacious', 'adjective', 'Lively and full of energy',
        'Let your curiosity be vivacious — ask, explore and wonder.'],
    ['Zenith', 'noun', 'The highest point',
        'You haven’t reached your zenith yet. Every word learned is another step up.'],
    ['Flourish', 'verb', 'To grow and do very well',
        'Like a garden, your vocabulary will flourish a little more each day.'],
    ['Nostalgia', 'noun', 'A happy-sad longing for the past',
        'Let a little nostalgia remind you how far you’ve come.'],
  ];
}
