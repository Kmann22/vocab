import 'dart:math';

class HangarooGame {
  final List<String> wordList;
  late String currentWord;
  late List<String> hiddenWord;
  final Set<String> guessedLetters = {};
  int remainingAttempts = 6; // The number of allowed incorrect guesses

  HangarooGame(this.wordList) {
    _selectRandomWord();
  }

  void _selectRandomWord() {
    final random = Random();
    currentWord = wordList[random.nextInt(wordList.length)].toUpperCase();
    hiddenWord = List.filled(currentWord.length, "_");
  }

  bool guessLetter(String letter) {
    letter = letter.toUpperCase();
    if (guessedLetters.contains(letter)) {
      return false; // Already guessed
    }
    guessedLetters.add(letter);

    if (currentWord.contains(letter)) {
      // Reveal the letter in hiddenWord
      for (int i = 0; i < currentWord.length; i++) {
        if (currentWord[i] == letter) {
          hiddenWord[i] = letter;
        }
      }
      return true;
    } else {
      remainingAttempts--;
      return false;
    }
  }

  bool isGameOver() {
    return remainingAttempts <= 0 || hiddenWord.join() == currentWord;
  }

  bool isWinner() {
    return hiddenWord.join() == currentWord;
  }

  void resetGame() {
    guessedLetters.clear();
    remainingAttempts = 6;
    _selectRandomWord();
  }

  String getWordState() {
    return hiddenWord.join(" ");
  }

  int getRemainingAttempts() {
    return remainingAttempts;
  }

  String getCurrentWord() {
    return currentWord;
  }
}
