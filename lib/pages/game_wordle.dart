import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocab/services/words.dart';
import 'wordle_game.dart';

class WordlePage extends StatefulWidget {
  @override
  _WordlePageState createState() => _WordlePageState();
}

class _WordlePageState extends State<WordlePage> {
  WordleGame? game;
  final TextEditingController _controller = TextEditingController();
  String message = '';
  late Future<List<DocumentSnapshot>> wordsFuture;
  String? meaning;
  int wordLength = 5; // Specify the desired word length

  @override
  void initState() {
    super.initState();
    // Fetch words and initialize the game once data is available
    wordsFuture = Words().fetchAllWords();
    wordsFuture.then((words) {
      _initializeGame(words.map((doc) => doc['Word'].toString()).toList());
    });
  }

  // Initialize the Wordle game with the word list
  void _initializeGame(List<String> wordList) {
    setState(() {
      game = WordleGame(wordList, wordLength: wordLength);
    });
  }

  // Handle guess submission
  Future<void> _submitGuess() async {
    if (game == null) return;

    String guess = _controller.text.trim();

    if (guess.length != game!.wordLength) {
      setState(() {
        message = 'Please enter a ${game!.wordLength}-letter word';
      });
      return;
    }

    try {
      bool correct = game!.guessWord(guess);
      String? newMeaning;

      if (correct) {
        newMeaning = await _getWordMeaning(guess);
        setState(() {
          message = 'Congratulations! You guessed the word!';
          meaning = newMeaning;
        });
      } else if (game!.isGameOver()) {
        newMeaning = await _getWordMeaning(game!.getTargetWord());
        setState(() {
          message = 'Game Over! The word was ${game!.getTargetWord()}';
          meaning = newMeaning;
        });
      } else {
        setState(() {
          message = 'Try again!';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Invalid guess';
      });
    }

    _controller.clear();
  }

  // Retrieve word meaning from the database
  Future<String?> _getWordMeaning(String word) async {
    final words = await wordsFuture;
    for (var doc in words) {
      if (doc['Word'].toString().toUpperCase() == word.toUpperCase()) {
        return doc['Meaning'];
      }
    }
    return null;
  }

  // Restart the game
  void _restartGame() {
    if (game == null) return;

    setState(() {
      game!.resetGame();
      message = '';
      meaning = null;
    });
  }

  // Build the main UI
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: wordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Failed to load words'));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Wordle Clone'),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _restartGame,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildGuessGrid(),
                SizedBox(height: 20),
                _buildInputField(),
                SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                if (meaning != null) ...[
                  SizedBox(height: 10),
                  Text(
                    'Meaning: $meaning',
                    style: TextStyle(fontSize: 16, color: Colors.green),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Build the grid to display guessed words
  Widget _buildGuessGrid() {
    if (game == null) return SizedBox();

    List<String> guessedWords = game!.getGuessedWords();

    return Expanded(
      child: GridView.builder(
        itemCount: game!.maxAttempts,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 8.0,
          mainAxisExtent: 60.0,
        ),
        itemBuilder: (context, index) {
          String word = index < guessedWords.length ? guessedWords[index] : '';
          return _buildGuessRow(word);
        },
      ),
    );
  }

  // Build each row of the guess grid
  Widget _buildGuessRow(String word) {
    if (game == null) return SizedBox();

    List<Color> colors = _getLetterColors(word);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(game!.wordLength, (index) {
        String letter = index < word.length ? word[index] : '';
        return _buildLetterBox(letter, colors[index]);
      }),
    );
  }

  // Build a box for each letter in a guess
  Widget _buildLetterBox(String letter, Color color) {
    return Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Build the input field for guesses
  Widget _buildInputField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your guess',
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: game?.wordLength, // Use the game's word length
            onSubmitted: (value) => _submitGuess(),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: _submitGuess,
          child: Text('Submit'),
        ),
      ],
    );
  }

  // Determine colors for each letter in a guess
  List<Color> _getLetterColors(String word) {
    if (game == null)
      return List.generate(game!.wordLength, (index) => Colors.grey);

    List<Color> colors =
        List.generate(game!.wordLength, (index) => Colors.grey);

    String targetWord = game!.getTargetWord();

    for (int i = 0; i < word.length; i++) {
      if (i >= targetWord.length) break; // Prevent out-of-range access

      if (word[i] == targetWord[i]) {
        colors[i] = Colors.green;
      } else if (targetWord.contains(word[i])) {
        colors[i] = Colors.yellow;
      }
    }

    return colors;
  }
}
