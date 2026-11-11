import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/word_entry.dart';
import '../services/word_api_service.dart';
import '../services/words.dart';
import '../theme.dart';
import '../widgets/common.dart';

class NewWordPage extends StatefulWidget {
  const NewWordPage({super.key});

  @override
  State<NewWordPage> createState() => _NewWordPageState();
}

enum _LookupState { idle, loading, found, notFound }

class _NewWordPageState extends State<NewWordPage> {
  final _formKey = GlobalKey<FormState>();
  final _wordFocus = FocusNode();

  final _word = TextEditingController();
  final _type = TextEditingController();
  final _meaning = TextEditingController();
  final _sentence = TextEditingController();
  final _pronunciation = TextEditingController();
  final _synonyms = TextEditingController();
  final _antonyms = TextEditingController();

  final _api = WordApiService();
  final _repo = WordRepository();

  Timer? _debounce;
  int _lookupId = 0;
  _LookupState _lookup = _LookupState.idle;
  bool _saving = false;

  /// What the lookup last put in each field. A field is only overwritten by
  /// a new lookup if it is empty or still holds that auto-filled value, so
  /// anything the user typed themselves is never replaced.
  final Map<TextEditingController, String> _autoFilled = {};

  static const _commonTypes = ['noun', 'verb', 'adjective', 'adverb', 'phrase'];

  List<TextEditingController> get _detailFields =>
      [_type, _meaning, _sentence, _pronunciation, _synonyms, _antonyms];

  @override
  void initState() {
    super.initState();
    _word.addListener(_onWordChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _word.removeListener(_onWordChanged);
    for (final c in [_word, ..._detailFields]) {
      c.dispose();
    }
    _wordFocus.dispose();
    super.dispose();
  }

  String _lastWord = '';

  void _onWordChanged() {
    final text = _word.text.trim();
    if (text == _lastWord) return; // cursor moves etc.
    _lastWord = text;
    _debounce?.cancel();
    if (text.isEmpty) {
      _clearAutoFilled();
      setState(() => _lookup = _LookupState.idle);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _runLookup(text));
  }

  Future<void> _runLookup(String word) async {
    final id = ++_lookupId;
    setState(() => _lookup = _LookupState.loading);
    final details = await _api.lookup(word);
    if (!mounted || id != _lookupId) return; // a newer lookup started

    if (details == null) {
      setState(() => _lookup = _LookupState.notFound);
      return;
    }
    setState(() {
      _lookup = _LookupState.found;
      _fill(_type, details.type);
      _fill(_meaning, details.meaning);
      _fill(_sentence, details.sentence);
      _fill(_pronunciation, details.pronunciation);
      _fill(_synonyms, details.synonyms.join(', '));
      _fill(_antonyms, details.antonyms.join(', '));
    });
  }

  void _fill(TextEditingController c, String value) {
    final current = c.text;
    if (current.isEmpty || current == _autoFilled[c]) {
      c.text = value;
      _autoFilled[c] = value;
    }
  }

  void _clearAutoFilled() {
    for (final c in _detailFields) {
      if (_autoFilled[c] != null && c.text == _autoFilled[c]) c.clear();
    }
    _autoFilled.clear();
  }

  List<String> _splitList(String text) =>
      text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final entry = WordEntry(
      word: _word.text.trim(),
      type: _type.text.trim().toLowerCase(),
      meaning: _meaning.text.trim(),
      sentence: _sentence.text.trim(),
      pronunciation: _pronunciation.text.trim(),
      synonyms: _splitList(_synonyms.text),
      antonyms: _splitList(_antonyms.text),
    );

    setState(() => _saving = true);
    try {
      if (await _repo.exists(entry.word, entry.type)) {
        if (!mounted) return;
        final addAnyway = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('“${entry.word}” is already saved'),
            content: Text(
              'There’s already a ${entry.type.isEmpty ? '' : '${entry.type} '}entry for this word. '
              'Add yours as another meaning?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add anyway')),
            ],
          ),
        );
        if (addAnyway != true) {
          if (mounted) setState(() => _saving = false);
          return;
        }
      }

      final saved = await _repo.addWord(entry);
      if (!mounted) return;
      _resetForm();
      showMessage(
        context,
        '“${saved.word}” added to the dictionary',
        action: SnackBarAction(
          label: 'Share',
          onPressed: () => Share.share(saved.toShareText()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Couldn’t save the word. Check your connection and try again.');
    }
  }

  void _resetForm() {
    _debounce?.cancel();
    _lookupId++;
    _lastWord = '';
    for (final c in [_word, ..._detailFields]) {
      c.clear();
    }
    _autoFilled.clear();
    setState(() {
      _saving = false;
      _lookup = _LookupState.idle;
    });
    _formKey.currentState?.reset();
    _wordFocus.requestFocus();
  }

  Widget? _lookupIndicator() {
    switch (_lookup) {
      case _LookupState.loading:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
        );
      case _LookupState.found:
        return const Icon(Icons.check_circle_rounded, color: WW.correct);
      case _LookupState.notFound:
      case _LookupState.idle:
        return null;
    }
  }

  String? get _lookupHelper {
    switch (_lookup) {
      case _LookupState.loading:
        return 'Looking it up…';
      case _LookupState.found:
        return 'Filled in from the dictionary — edit anything you like.';
      case _LookupState.notFound:
        return 'Not found online. You can fill in the details yourself.';
      case _LookupState.idle:
        return 'We’ll look it up and fill in the details for you.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ADD A WORD')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Constrained(
                maxWidth: 640,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WWCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _word,
                            focusNode: _wordFocus,
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              labelText: 'Word',
                              hintText: 'e.g. serendipity',
                              helperText: _lookupHelper,
                              helperMaxLines: 2,
                              suffixIcon: _lookupIndicator(),
                            ),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Enter a word';
                              if (!RegExp(r"^[A-Za-z][A-Za-z '\-]*$").hasMatch(value)) {
                                return 'Use letters only (spaces, hyphens and apostrophes are fine)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _type,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(labelText: 'Type', hintText: 'noun, verb…'),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final t in _commonTypes)
                                ChoiceChip(
                                  label: Text(t),
                                  selected: _type.text.trim().toLowerCase() == t,
                                  onSelected: (_) => setState(() => _type.text = t),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _meaning,
                            minLines: 2,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(labelText: 'Meaning', alignLabelWithHint: true),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Add a meaning' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    WWCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Optional details',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _sentence,
                            minLines: 1,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(labelText: 'Example sentence'),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _pronunciation,
                            decoration: const InputDecoration(labelText: 'Pronunciation'),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _synonyms,
                            decoration: const InputDecoration(
                              labelText: 'Synonyms',
                              helperText: 'Separate with commas',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _antonyms,
                            decoration: const InputDecoration(
                              labelText: 'Antonyms',
                              helperText: 'Separate with commas',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ArrowButton(label: 'SAVE WORD', expand: true, loading: _saving, onPressed: _save),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
