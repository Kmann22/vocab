import 'package:cloud_firestore/cloud_firestore.dart';

class Words {
  final CollectionReference _wordsCollection =
      FirebaseFirestore.instance.collection('Words');

  Future<void> addWord(
      String word,
      String sentence,
      String pronunciation,
      String type,
      String meaning,
      List<String> synonyms,
      List<String> antonyms) async {
    try {
      await _wordsCollection.add({
        'Word': word,
        'Sentence': sentence,
        'Pronunciation': pronunciation,
        'Type': type,
        'Meaning': meaning,
        'Synonyms': synonyms,
        'Antonyms': antonyms,
      });
    } catch (e) {
      throw Exception('Error adding word: $e');
    }
  }

  Future<bool> checkIfWordExists(String word, String type) async {
    try {
      QuerySnapshot querySnapshot = await _wordsCollection
          .where('Word', isEqualTo: word)
          .where('Type', isEqualTo: type)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking word existence: $e');
    }
  }
}
