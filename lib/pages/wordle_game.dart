import 'dart:math';

class WordleGame {
  final List<String> _wordList;
  late String _targetWord;
  final List<String> _guessedWords = [];
  final int maxAttempts;
  final int wordLength;

  WordleGame(this._wordList, {this.maxAttempts = 6, this.wordLength = 5}) {
    // Filter the words by length
    List<String> filteredWords =
        _wordList.where((word) => word.length == wordLength).toList();

    // Check if the filtered word list is empty
    if (filteredWords.isEmpty) {
      throw ArgumentError(
          "No words of length $wordLength found in the word list.");
    }

    // Choose a random word from the filtered list as the target word
    _targetWord =
        filteredWords[Random().nextInt(filteredWords.length)].toUpperCase();
  }

  // Method to handle guesses
  bool guessWord(String guess) {
    if (guess.length != wordLength) {
      throw ArgumentError(
          'The guessed word must be exactly $wordLength letters long.');
    }

    guess = guess.toUpperCase();

    if (_guessedWords.contains(guess)) {
      throw ArgumentError('Word has already been guessed.');
    }

    _guessedWords.add(guess);

    return guess == _targetWord;
  }

  // Get the target word
  String getTargetWord() {
    return _targetWord;
  }

  // Get the list of guessed words
  List<String> getGuessedWords() {
    return _guessedWords;
  }

  // Reset the game
  void resetGame() {
    // Re-choose a new target word
    List<String> filteredWords =
        _wordList.where((word) => word.length == wordLength).toList();
    _targetWord =
        filteredWords[Random().nextInt(filteredWords.length)].toUpperCase();
    _guessedWords.clear();
  }

  // Check if the game is over
  bool isGameOver() {
    return _guessedWords.length >= maxAttempts ||
        _guessedWords.contains(_targetWord);
  }

  // Get feedback on a guess
  List<int> getFeedback(String guess) {
    if (guess.length != wordLength) {
      throw ArgumentError(
          'The guessed word must be exactly $wordLength letters long.');
    }

    List<int> feedback = List.filled(wordLength, 0);

    // Creating a copy of target word to track correct matches
    List<String> targetWordChars = _targetWord.split('');

    // Check for correct positions first
    for (int i = 0; i < wordLength; i++) {
      if (guess[i] == _targetWord[i]) {
        feedback[i] = 2; // Green (correct position)
        targetWordChars[i] = ''; // Remove matched letter
      }
    }

    // Check for correct letters in incorrect positions
    for (int i = 0; i < wordLength; i++) {
      if (feedback[i] == 0 && targetWordChars.contains(guess[i])) {
        feedback[i] = 1; // Yellow (correct letter, wrong position)
        targetWordChars[targetWordChars.indexOf(guess[i])] =
            ''; // Remove matched letter
      }
    }

    return feedback;
  }
}
