import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OurDictionary extends StatefulWidget {
  @override
  _OurDictionaryState createState() => _OurDictionaryState();
}

class _OurDictionaryState extends State<OurDictionary> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dictionary'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: WordSearch());
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Words')
            .orderBy('Word') // Ensure 'word' is indexed in Firestore
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child:
                  CircularProgressIndicator(), // Show loading indicator while data is loading
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No words found in the dictionary.',
                style: TextStyle(fontSize: 24),
              ),
            );
          }

          final words = snapshot.data!.docs;

          return ListView.separated(
            itemCount: words.length,
            separatorBuilder: (context, index) {
              final currentWord = words[index].data() as Map<String, dynamic>;
              final nextWord =
                  words[index + 1 < words.length ? index + 1 : index].data()
                      as Map<String, dynamic>;

              final currentLetter = currentWord['Word'][0].toUpperCase();
              final nextLetter = nextWord['Word'][0].toUpperCase();

              if (currentLetter != nextLetter) {
                return Divider(
                  thickness: 2,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                );
              }
              return SizedBox.shrink();
            },
            itemBuilder: (context, index) {
              final wordData = words[index].data() as Map<String, dynamic>;

              final word = wordData['Word'] ??
                  'Unknown'; // Ensure field name matches Firestore
              final pronunciation = wordData['Pronunciation'] ?? '';
              final type = wordData['Type'] ?? '';
              final meaning = wordData['Meaning'] ?? '';
              final synonyms = List<String>.from(wordData['Synonyms'] ?? []);
              final antonyms = List<String>.from(wordData['Antonyms'] ?? []);

              // Determine if this is the first word of a new letter section
              final isFirstInSection = index == 0 ||
                  (words[index - 1].data() as Map<String, dynamic>)['Word'][0]
                          .toUpperCase() !=
                      word[0].toUpperCase();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFirstInSection)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        word[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ListTile(
                    title: Text(
                      word,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to WordDetailPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WordDetailPage(
                            word: word,
                            pronunciation: pronunciation,
                            type: type,
                            meaning: meaning,
                            synonyms: synonyms,
                            antonyms: antonyms,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class WordDetailPage extends StatelessWidget {
  final String word;
  final String pronunciation;
  final String type;
  final String meaning;
  final List<String> synonyms;
  final List<String> antonyms;

  WordDetailPage({
    required this.word,
    required this.pronunciation,
    required this.type,
    required this.meaning,
    required this.synonyms,
    required this.antonyms,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(word),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Pronunciation: $pronunciation',
                style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 8),
              Text(
                'Type: $type',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 16),
              Text(
                'Meaning:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                meaning,
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 16),
              if (synonyms.isNotEmpty) ...[
                Text(
                  'Synonyms:',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  synonyms.join(', '),
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 16),
              ],
              if (antonyms.isNotEmpty) ...[
                Text(
                  'Antonyms:',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  antonyms.join(', '),
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WordSearch extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Words')
          .orderBy('Word')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No words found in the dictionary.',
              style: TextStyle(fontSize: 24),
            ),
          );
        }

        final words = snapshot.data!.docs.where((doc) {
          final word = (doc.data() as Map<String, dynamic>)['Word'] ?? '';
          return word.toLowerCase().contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: words.length,
          itemBuilder: (context, index) {
            final wordData = words[index].data() as Map<String, dynamic>;

            final word = wordData['Word'] ?? 'Unknown';
            final pronunciation = wordData['Pronunciation'] ?? '';
            final type = wordData['Type'] ?? '';
            final meaning = wordData['Meaning'] ?? '';
            final synonyms = List<String>.from(wordData['Synonyms'] ?? []);
            final antonyms = List<String>.from(wordData['Antonyms'] ?? []);

            return ListTile(
              title: Text(
                word,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WordDetailPage(
                      word: word,
                      pronunciation: pronunciation,
                      type: type,
                      meaning: meaning,
                      synonyms: synonyms,
                      antonyms: antonyms,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
