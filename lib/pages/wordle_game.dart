import 'dart:math';

/// Result for one letter of a guess.
enum LetterResult { absent, present, correct }

/// Pure game logic for Wordle (no Flutter), so it can be unit-tested.
class WordleGame {
  WordleGame(Iterable<String> words, {required this.wordLength, this.maxAttempts = 6, Random? random})
      : _random = random ?? Random(),
        _words = wordsOfLength(words, wordLength) {
    if (_words.isEmpty) {
      throw ArgumentError('No $wordLength-letter words available.');
    }
    _target = _words[_random.nextInt(_words.length)];
  }

  final int wordLength;
  final int maxAttempts;
  final Random _random;
  final List<String> _words;

  late String _target;
  final List<String> _guesses = [];
  final List<List<LetterResult>> _results = [];

  static List<String> wordsOfLength(Iterable<String> words, int length) {
    final ok = RegExp('^[A-Z]{$length}\$');
    return words.map((w) => w.trim().toUpperCase()).where(ok.hasMatch).toSet().toList();
  }

  static const minLength = 3;
  static const maxLength = 10;

  /// How many playable words there are of each length (3–10 letters).
  static Map<int, int> lengthCounts(Iterable<String> words) {
    final counts = <int, int>{};
    final ok = RegExp('^[A-Z]{$minLength,$maxLength}\$');
    for (final w in words.map((w) => w.trim().toUpperCase()).toSet()) {
      if (ok.hasMatch(w)) counts[w.length] = (counts[w.length] ?? 0) + 1;
    }
    return counts;
  }

  /// Picks the best word length to play: 5 if possible, otherwise the length
  /// with the most words. Returns null if nothing is playable.
  static int? bestLength(Iterable<String> words) {
    final counts = lengthCounts(words);
    if (counts.isEmpty) return null;
    if (counts.containsKey(5)) return 5;
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  String get target => _target;
  List<String> get guesses => List.unmodifiable(_guesses);
  List<List<LetterResult>> get results => List.unmodifiable(_results);

  bool get isWon => _guesses.isNotEmpty && _guesses.last == _target;
  bool get isOver => isWon || _guesses.length >= maxAttempts;

  /// Throws [ArgumentError] with a friendly message when the guess is invalid.
  List<LetterResult> guess(String input) {
    final g = input.trim().toUpperCase();
    if (isOver) throw ArgumentError('The game is over.');
    if (g.length != wordLength) throw ArgumentError('Use $wordLength letters.');
    if (!RegExp(r'^[A-Z]+$').hasMatch(g)) throw ArgumentError('Letters only.');
    if (_guesses.contains(g)) throw ArgumentError('You already tried $g.');
    final r = evaluate(g, _target);
    _guesses.add(g);
    _results.add(r);
    return r;
  }

  /// Standard Wordle scoring, handling repeated letters correctly.
  static List<LetterResult> evaluate(String guess, String target) {
    final g = guess.toUpperCase(), t = target.toUpperCase();
    final result = List.filled(g.length, LetterResult.absent);
    final remaining = <String, int>{};

    for (var i = 0; i < g.length; i++) {
      if (g[i] == t[i]) {
        result[i] = LetterResult.correct;
      } else {
        remaining[t[i]] = (remaining[t[i]] ?? 0) + 1;
      }
    }
    for (var i = 0; i < g.length; i++) {
      if (result[i] == LetterResult.correct) continue;
      final left = remaining[g[i]] ?? 0;
      if (left > 0) {
        result[i] = LetterResult.present;
        remaining[g[i]] = left - 1;
      }
    }
    return result;
  }

  /// Best result seen so far for each letter, for colouring the keyboard.
  Map<String, LetterResult> get keyboard {
    final map = <String, LetterResult>{};
    for (var row = 0; row < _guesses.length; row++) {
      for (var i = 0; i < wordLength; i++) {
        final letter = _guesses[row][i];
        final r = _results[row][i];
        final prev = map[letter];
        if (prev == null || r.index > prev.index) map[letter] = r;
      }
    }
    return map;
  }

  void reset() {
    _guesses.clear();
    _results.clear();
    if (_words.length > 1) {
      String next;
      do {
        next = _words[_random.nextInt(_words.length)];
      } while (next == _target);
      _target = next;
    }
  }
}
