import 'package:cloud_firestore/cloud_firestore.dart';

class Words {
  final CollectionReference _wordsCollection =
      FirebaseFirestore.instance.collection('Words');

  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('Users');

  // Method to add a word with additional user information
  Future<void> addWord(
      String word,
      String sentence,
      String pronunciation,
      String type,
      String meaning,
      List<String> synonyms,
      List<String> antonyms,
      String? userName, // Add a userName parameter
      String? userEmail) async {
    try {
      // Generate a unique document ID based on the word and type
      String documentId = await _generateUniqueDocumentId(word, type);

      await _wordsCollection.doc(documentId).set({
        'Word': word,
        'Sentence': sentence,
        'Pronunciation': pronunciation,
        'Type': type,
        'Meaning': meaning,
        'Synonyms': synonyms,
        'Antonyms': antonyms,
        'AddedBy':
            userName, // Store the user's name or 'Anonymous' if not provided
        'Timestamp': FieldValue
            .serverTimestamp(), // Add a timestamp for when the word is added
      });

      await _userCollection
          .doc(userEmail)
          .collection('AddedWords')
          .doc(documentId)
          .set({
        'Word': word,
        'Sentence': sentence,
        'Pronunciation': pronunciation,
        'Type': type,
        'Meaning': meaning,
        'Synonyms': synonyms,
        'Antonyms': antonyms,
        'AddedBy':
            userName, // Store the user's name or 'Anonymous' if not provided
        'Timestamp': FieldValue
            .serverTimestamp(), // Add a timestamp for when the word is added
      });
    } catch (e) {
      throw Exception('Error adding word: $e');
    }
  }

  // Helper method to generate a unique document ID
  Future<String> _generateUniqueDocumentId(String word, String type) async {
    int suffix = 1;
    String documentId = '$word-$type-$suffix';

    // Loop to ensure the document ID is unique
    while (await _documentExists(documentId)) {
      suffix++;
      documentId =
          '$word-$type-$suffix'; // Update the document ID with a new suffix
    }

    return documentId;
  }

  // Method to check if a document with the given ID already exists
  Future<bool> _documentExists(String documentId) async {
    try {
      // Check if a document with the specific ID exists
      DocumentSnapshot document = await _wordsCollection.doc(documentId).get();
      return document
          .exists; // Return true if the document exists, otherwise false
    } catch (e) {
      throw Exception('Error checking document existence: $e');
    }
  }

  // Method to check if a word with the same type already exists
  Future<bool> checkIfWordExists(String word, String type) async {
    try {
      // Query Firestore to check for the existence of the word with the given type
      QuerySnapshot querySnapshot = await _wordsCollection
          .where('Word', isEqualTo: word)
          .where('Type', isEqualTo: type)
          .get();

      return querySnapshot.docs
          .isNotEmpty; // Return true if documents are found, otherwise false
    } catch (e) {
      throw Exception('Error checking word existence: $e');
    }
  }

  // Method to fetch all words from the collection
  Future<List<DocumentSnapshot>> fetchAllWords() async {
    try {
      // Retrieve all documents from the collection
      QuerySnapshot querySnapshot = await _wordsCollection.get();
      return querySnapshot.docs; // Return the list of document snapshots
    } catch (e) {
      throw Exception('Error fetching all words: $e');
    }
  }
}
