import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocab/services/words.dart';

class NewWordPage extends StatelessWidget {
  final TextEditingController wordController = TextEditingController();
  final TextEditingController meaningController = TextEditingController();
  final TextEditingController synonymsController = TextEditingController();
  final TextEditingController antonymsController = TextEditingController();
  final TextEditingController pronunciationController = TextEditingController();
  final TextEditingController typeController = TextEditingController();

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
      newWord.addWord(word, pronunciation, type, meaning, synonyms, antonyms);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Word added successfully')),
      );

      // Clear the text fields
      wordController.clear();
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
