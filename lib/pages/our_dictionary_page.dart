import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OurDictionary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dictionary'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Words')
            .orderBy('word') // Order the documents alphabetically by 'word'
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child:
                  CircularProgressIndicator(), // Show a loading indicator while data is loading
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No words found in the dictionary.',
                  style: TextStyle(fontSize: 24)),
            );
          }

          final words = snapshot.data!.docs;

          return ListView.builder(
            itemCount: words.length,
            itemBuilder: (context, index) {
              final wordData = words[index].data() as Map<String, dynamic>;

              final word = wordData['word'] ?? 'Unknown';
              final pronunciation = wordData['pronunciation'] ?? 'Unknown';
              final type = wordData['type'] ?? 'Unknown';
              final meaning = wordData['meaning'] ?? 'No meaning available';

              return ListTile(
                title: Text(
                  word,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pronunciation: $pronunciation'),
                    Text('Type: $type'),
                    Text('Meaning: $meaning'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
