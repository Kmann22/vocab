import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocab/services/words.dart';
import 'package:vocab/services/word_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewWordPage extends StatefulWidget {
  @override
  _NewWordPageState createState() => _NewWordPageState();
}

class _NewWordPageState extends State<NewWordPage> {
  final TextEditingController wordController = TextEditingController();
  final TextEditingController meaningController = TextEditingController();
  final TextEditingController sentenceController = TextEditingController();
  final TextEditingController synonymsController = TextEditingController();
  final TextEditingController antonymsController = TextEditingController();
  final TextEditingController pronunciationController = TextEditingController();
  final TextEditingController typeController = TextEditingController();

  final WordApiService _wordApiService = WordApiService();
  final Words _wordsService = Words();
  Timer? _debounce;

  String? _userName;

  @override
  void initState() {
    super.initState();
    wordController.addListener(_onWordChanged);
    _fetchUserName();
  }

  @override
  void dispose() {
    wordController.removeListener(_onWordChanged);
    wordController.dispose();
    meaningController.dispose();
    sentenceController.dispose();
    synonymsController.dispose();
    antonymsController.dispose();
    pronunciationController.dispose();
    typeController.dispose();
    super.dispose();
  }

  void _onWordChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchWordDetails(wordController.text);
    });
  }

  Future<void> _fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userName = user.displayName;
      });
    }
  }

  Future<void> _fetchWordDetails(String word) async {
    if (word.isEmpty) return;

    final wordDetails = await _wordApiService.fetchWordDetails(word);

    if (wordDetails != null) {
      setState(() {
        meaningController.text = wordDetails['meaning'] ?? '';
        sentenceController.text = wordDetails['sentence'] ?? '';
        pronunciationController.text = wordDetails['pronunciation'] ?? '';
        typeController.text = wordDetails['type'] ?? '';
        synonymsController.text =
            (wordDetails['synonyms'] as List<dynamic>).join(', ');
        antonymsController.text =
            (wordDetails['antonyms'] as List<dynamic>).join(', ');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Word'),
        backgroundColor: Colors.indigo,
        elevation: 4.0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTextField(
              controller: wordController,
              label: 'Word',
              hint: 'Enter a new word',
            ),
            const SizedBox(height: 10),
            buildTextField(
              controller: sentenceController,
              label: 'Sentence',
              hint: 'Enter an example sentence',
            ),
            const SizedBox(height: 10),
            buildTextField(
              controller: pronunciationController,
              label: 'Pronunciation',
              hint: 'Enter pronunciation',
            ),
            const SizedBox(height: 10),
            buildTextField(
              controller: typeController,
              label: 'Type',
              hint: 'Enter type (e.g., noun, verb)',
            ),
            const SizedBox(height: 10),
            buildTextField(
              controller: meaningController,
              label: 'Meaning',
              hint: 'Enter meaning',
            ),
            const SizedBox(height: 10),
            buildTextField(
              controller: synonymsController,
              label: 'Synonyms',
              hint: 'Enter synonyms $_userName (comma-separated)',
            ),
            const SizedBox(height: 10),
            buildTextField(
              controller: antonymsController,
              label: 'Antonyms',
              hint: 'Enter antonyms (comma-separated)',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _checkAndAddWord(context),
              child: const Text(
                'Add Word',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Future<void> _checkAndAddWord(BuildContext context) async {
    String word = wordController.text.trim();
    String sentence = sentenceController.text.trim();
    String pronunciation = pronunciationController.text.trim();
    String type = typeController.text.trim();
    String meaning = meaningController.text.trim();
    List<String> synonyms = synonymsController.text
        .split(',')
        .map((synonym) => synonym.trim())
        .toList();
    List<String> antonyms = antonymsController.text
        .split(',')
        .map((antonym) => antonym.trim())
        .toList();

    if (word.isEmpty || meaning.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word and meaning are required')),
      );
      return;
    }

    // Check if the word already exists in the Firestore database
    bool exists = await _wordsService.checkIfWordExists(word, type);

    if (exists) {
      // Show a confirmation dialog
      bool? addDifferentMeaning = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Word already exists'),
          content: const Text(
              'This word already exists. Do you want to add a different meaning or type for the same word?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      );

      if (addDifferentMeaning == true) {
        // User confirmed to add a different meaning or type
        _addWord(context);
      }
    } else {
      // Word does not exist, proceed to add it
      _addWord(context);
    }
  }

  Future<void> _addWord(BuildContext context) async {
    String word = wordController.text.trim();
    String sentence = sentenceController.text.trim();
    String pronunciation = pronunciationController.text.trim();
    String type = typeController.text.trim();
    String meaning = meaningController.text.trim();
    List<String> synonyms = synonymsController.text
        .split(',')
        .map((synonym) => synonym.trim())
        .toList();
    List<String> antonyms = antonymsController.text
        .split(',')
        .map((antonym) => antonym.trim())
        .toList();

    try {
      Words newWord = Words();
      await newWord.addWord(word, sentence, pronunciation, type, meaning,
          synonyms, antonyms, _userName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word added successfully')),
      );

      // Format the message with bold titles using asterisks for emphasis
      String message = """
📚 *Word:* $word
🔊 *Pronunciation:* $pronunciation
📖 *Meaning:* $meaning
✍️ *Sentence:* $sentence
📋 *Type:* $type
🔗 *Synonyms:* ${synonyms.join(', ')}
❌ *Antonyms:* ${antonyms.join(', ')}
      """;

      await Share.share(message);

      // Clear the text fields
      wordController.clear();
      sentenceController.clear();
      pronunciationController.clear();
      typeController.clear();
      meaningController.clear();
      synonymsController.clear();
      antonymsController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add word: $e')),
      );
    }
  }
}
