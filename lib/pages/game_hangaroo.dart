import 'package:flutter/material.dart';
import 'package:vocab/services/words.dart'; // Assuming this provides access to the word list
import 'hangaroo_game.dart';

class HangarooPage extends StatefulWidget {
  @override
  _HangarooPageState createState() => _HangarooPageState();
}

class _HangarooPageState extends State<HangarooPage> {
  HangarooGame? game; // Allow nullability to handle uninitialized state
  late Future<List<String>> wordsFuture;
  bool gameInitialized = false;

  @override
  void initState() {
    super.initState();
    wordsFuture = _fetchWords();
  }

  Future<List<String>> _fetchWords() async {
    final wordsService = Words(); // Assuming this is your class to fetch words
    final wordDocs =
        await wordsService.fetchAllWords(); // Fetch words from Firestore
    return wordDocs.map((doc) => doc['Word'].toString()).toList();
  }

  void _initializeGame(List<String> wordList) {
    // Initialize the game if it's not already initialized
    if (!gameInitialized) {
      setState(() {
        game = HangarooGame(wordList);
        gameInitialized = true; // Mark as initialized
      });
    }
  }

  void _guessLetter(String letter) {
    setState(() {
      game?.guessLetter(letter); // Use null-aware access
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: wordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Failed to load words'));
        }

        // Safely initialize the game after data is ready
        if (!gameInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeGame(snapshot.data!);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Hangaroo Game'),
            backgroundColor: Colors.indigo,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Word: ${game?.getWordState() ?? ''}', // Use null check
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Remaining Attempts: ${game?.getRemainingAttempts() ?? 0}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                _buildAlphabetGrid(),
                SizedBox(height: 20),
                _buildGameStatus(),
                ElevatedButton(
                  onPressed: game != null
                      ? () {
                          setState(() {
                            game!.resetGame(); // Ensure game is not null
                            gameInitialized = false; // Reset initialization
                          });
                        }
                      : null,
                  child: Text('Restart Game'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlphabetGrid() {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: alphabet.split('').map((letter) {
        return ElevatedButton(
          onPressed: game != null && !game!.isGameOver()
              ? () => _guessLetter(letter)
              : null,
          child: Text(letter, style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                game != null && game!.guessedLetters.contains(letter)
                    ? Colors.black
                    : Colors.indigo,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGameStatus() {
    if (game != null && game!.isGameOver()) {
      return Text(
        game!.isWinner()
            ? 'You Won! The word was ${game!.getCurrentWord()}.'
            : 'Game Over! The word was ${game!.getCurrentWord()}',
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
      );
    }
    return SizedBox.shrink();
  }
}
