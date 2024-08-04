import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocab/services/words.dart';
import 'package:vocab/services/word_api_service.dart';

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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    wordController.addListener(_onWordChanged);
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

  Future<void> _fetchWordDetails(String word) async {
    if (word.isEmpty) return;

    final wordDetails = await _wordApiService.fetchWordDetails(word);

    if (wordDetails != null) {
      meaningController.text = wordDetails['meaning'] ?? '';
      sentenceController.text = wordDetails['sentence'] ?? '';
      pronunciationController.text = wordDetails['pronunciation'] ?? '';
      typeController.text = wordDetails['type'] ?? '';
      synonymsController.text =
          (wordDetails['synonyms'] as List<dynamic>).join(', ');
      antonymsController.text =
          (wordDetails['antonyms'] as List<dynamic>).join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Word'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: wordController,
              decoration: InputDecoration(labelText: 'Word'),
            ),
            TextField(
              controller: sentenceController,
              decoration: InputDecoration(labelText: 'Sentence'),
            ),
            TextField(
              controller: pronunciationController,
              decoration: InputDecoration(labelText: 'Pronunciation'),
            ),
            TextField(
              controller: typeController,
              decoration: InputDecoration(labelText: 'Type (e.g., noun, verb)'),
            ),
            TextField(
              controller: meaningController,
              decoration: InputDecoration(labelText: 'Meaning'),
            ),
            TextField(
              controller: synonymsController,
              decoration:
                  InputDecoration(labelText: 'Synonyms (comma-separated)'),
            ),
            TextField(
              controller: antonymsController,
              decoration:
                  InputDecoration(labelText: 'Antonyms (comma-separated)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addWord(context),
              child: Text('Add Word'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addWord(BuildContext context) async {
    String word = wordController.text.trim();
    String sentence = sentenceController.text.trim();
    String pronunciation = pronunciationController.text.trim();
    String type = typeController.text.trim();
    String meaning = meaningController.text.trim();
    List<String> synonyms = synonymsController.text.trim().split(',');
    List<String> antonyms = antonymsController.text.trim().split(',');

    if (word.isEmpty || meaning.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Word and meaning are required')),
      );
      return;
    }

    try {
      Words newWord = Words();
      newWord.addWord(
          word, sentence, pronunciation, type, meaning, synonyms, antonyms);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Word added successfully')),
      );

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
