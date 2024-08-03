import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Words {
  //get collection of notes
  final CollectionReference WordsDatabase =
      FirebaseFirestore.instance.collection('Words');

  //add new word
  Future<void> addWord(String Word, String Pronunciation, String Type,
      String Meaning, List<String> Synonyms, List<String> Antonyms) {
    return WordsDatabase.doc(Word.toUpperCase()).set({
      'Word': Word,
      'Pronunciation': Pronunciation,
      'Type': Type,
      'Meaning': Meaning,
      'Synonyms': Synonyms,
      'Antonym': Antonyms
    });
  }
}
