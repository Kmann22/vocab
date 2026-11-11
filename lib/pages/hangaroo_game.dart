import 'dart:math';

/// Pure game logic for Hangaroo (no Flutter), so it can be unit-tested.
class HangarooGame {
  HangarooGame(List<String> words, {this.maxMistakes = 6, Random? random})
      : _random = random ?? Random(),
        _words = playableWords(words) {
    if (_words.isEmpty) {
      throw ArgumentError('No playable words (letters only, 3+ characters).');
    }
    _pickWord();
  }

  final int maxMistakes;
  final Random _random;
  final List<String> _words;

  String _word = '';
  final Set<String> _guessed = {};
  int _mistakes = 0;

  /// Keeps words made only of letters A–Z with at least 3 letters.
  static List<String> playableWords(Iterable<String> words) {
    final ok = RegExp(r'^[A-Za-z]{3,}$');
    return words
        .map((w) => w.trim().toUpperCase())
        .where(ok.hasMatch)
        .toSet()
        .toList();
  }

  String get word => _word;
  Set<String> get guessedLetters => Set.unmodifiable(_guessed);
  int get mistakes => _mistakes;
  int get remainingAttempts => maxMistakes - _mistakes;

  bool get isWon => _word.split('').every(_guessed.contains);
  bool get isLost => _mistakes >= maxMistakes;
  bool get isOver => isWon || isLost;

  /// Letters shown to the player, with '_' for hidden ones.
  List<String> get revealed =>
      _word.split('').map((c) => _guessed.contains(c) || isLost ? c : '_').toList();

  bool isCorrectLetter(String letter) => _word.contains(letter.toUpperCase());

  /// Returns true if the letter is in the word. Ignored after game over or
  /// when the letter was already tried.
  bool guess(String letter) {
    final l = letter.toUpperCase();
    if (isOver || l.length != 1 || _guessed.contains(l)) return false;
    _guessed.add(l);
    if (_word.contains(l)) return true;
    _mistakes++;
    return false;
  }

  void reset() {
    _guessed.clear();
    _mistakes = 0;
    _pickWord();
  }

  void _pickWord() {
    if (_words.length == 1) {
      _word = _words.first;
      return;
    }
    String next;
    do {
      next = _words[_random.nextInt(_words.length)];
    } while (next == _word);
    _word = next;
  }
}
