import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/word_entry.dart';

/// All Firestore access for words and favourites.
///
/// Data layout (unchanged from the original app):
///   Words/{id}                              shared dictionary
///   Users/{email}/AddedWords/{id}           words a user added
///   Users/{email}/FavouriteWords/{id}       a user's favourites
class WordRepository {
  WordRepository({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _words => _db.collection('Words');

  DocumentReference<Map<String, dynamic>> _userDoc(String email) =>
      _db.collection('Users').doc(email);

  String get _email {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw StateError('Please log in again.');
    }
    return email;
  }

  /// Live list of every word, sorted A–Z ignoring case.
  Stream<List<WordEntry>> watchAll() {
    return _words.snapshots().map((snap) {
      final list = snap.docs
          .map(WordEntry.fromDoc)
          .where((w) => w.word.isNotEmpty)
          .toList()
        ..sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
      return list;
    });
  }

  /// All words, served from the local cache when possible so games start
  /// instantly. Falls back to the server the first time.
  Future<List<WordEntry>> fetchAll() async {
    List<WordEntry> parse(QuerySnapshot<Map<String, dynamic>> snap) =>
        snap.docs.map(WordEntry.fromDoc).where((w) => w.word.isNotEmpty).toList();
    try {
      final cached = parse(await _words.get(const GetOptions(source: Source.cache)));
      if (cached.isNotEmpty) {
        // Refresh the cache quietly for next time.
        _words.get(const GetOptions(source: Source.server)).ignore();
        return cached;
      }
    } catch (_) {
      // No cache yet (first launch) — use the server below.
    }
    return parse(await _words.get());
  }

  Future<bool> exists(String word, String type) async {
    final snap = await _words
        .where('Word', isEqualTo: word)
        .where('Type', isEqualTo: type)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Saves a word to the shared dictionary and to the user's own list.
  Future<WordEntry> addWord(WordEntry entry) async {
    final email = _email;
    final entryWithAuthor = WordEntry(
      word: entry.word,
      type: entry.type,
      meaning: entry.meaning,
      sentence: entry.sentence,
      pronunciation: entry.pronunciation,
      synonyms: entry.synonyms,
      antonyms: entry.antonyms,
      addedBy: _auth.currentUser?.displayName ?? 'Anonymous',
    );

    final id = await _uniqueId(entry.word, entry.type);
    final batch = _db.batch()
      ..set(_words.doc(id), entryWithAuthor.toMap())
      ..set(_userDoc(email).collection('AddedWords').doc(id), entryWithAuthor.toMap());
    await batch.commit();

    return WordEntry(
      id: id,
      word: entryWithAuthor.word,
      type: entryWithAuthor.type,
      meaning: entryWithAuthor.meaning,
      sentence: entryWithAuthor.sentence,
      pronunciation: entryWithAuthor.pronunciation,
      synonyms: entryWithAuthor.synonyms,
      antonyms: entryWithAuthor.antonyms,
      addedBy: entryWithAuthor.addedBy,
    );
  }

  Future<String> _uniqueId(String word, String type) async {
    // Firestore IDs cannot contain '/', so clean the parts first.
    String clean(String s) {
      final out = s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      return out.replaceAll(RegExp(r'^-+|-+$'), '');
    }

    final base = '${clean(word).isEmpty ? 'word' : clean(word)}-'
        '${clean(type).isEmpty ? 'other' : clean(type)}';
    var n = 1;
    while ((await _words.doc('$base-$n').get()).exists) {
      n++;
    }
    return '$base-$n';
  }

  /// IDs of the current user's favourite words.
  Stream<Set<String>> watchFavouriteIds() {
    final email = _auth.currentUser?.email;
    if (email == null) return Stream.value(<String>{});
    return _userDoc(email)
        .collection('FavouriteWords')
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toSet());
  }

  Future<void> setFavourite(WordEntry entry, bool favourite) async {
    final ref = _userDoc(_email).collection('FavouriteWords').doc(entry.id);
    if (favourite) {
      await ref.set(entry.toMap());
    } else {
      await ref.delete();
    }
  }

  Stream<int> watchAddedCount() {
    final email = _auth.currentUser?.email;
    if (email == null) return Stream.value(0);
    return _userDoc(email).collection('AddedWords').snapshots().map((s) => s.size);
  }
}
