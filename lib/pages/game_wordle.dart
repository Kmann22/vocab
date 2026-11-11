import 'dart:math';

import 'package:flutter/material.dart';

import '../models/word_entry.dart';
import '../services/words.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_widgets.dart';
import 'add_new_word.dart';
import 'wordle_game.dart';

/// Wordle settings. Kept for as long as the app is open.
class WordleSettings {
  WordleSettings._();

  /// Word length to play, or null for a random length each game.
  static int? length = 5;

  /// Number of guesses allowed.
  static int tries = 6;

  static const minTries = 3;
  static const maxTries = 10;
}

class WordlePage extends StatefulWidget {
  const WordlePage({super.key});

  @override
  State<WordlePage> createState() => _WordlePageState();
}

class _WordlePageState extends State<WordlePage> {
  final _repo = WordRepository();
  final _random = Random();
  late Future<List<WordEntry>> _load = _repo.fetchAll();

  WordleGame? _game;
  bool _loaded = false;
  Map<String, WordEntry> _entries = {};
  Map<int, int> _lengthCounts = {};
  String _current = '';
  int _shakeRow = -1;

  void _setup(List<WordEntry> words) {
    if (_loaded) return;
    _loaded = true;
    _entries = {for (final w in words) w.word.trim().toUpperCase(): w};
    _lengthCounts = WordleGame.lengthCounts(_entries.keys);
    _newGame();
  }

  /// Starts a new game using the current settings.
  void _newGame() {
    _current = '';
    if (_lengthCounts.isEmpty) {
      _game = null;
      return;
    }
    int length;
    final wanted = WordleSettings.length;
    if (wanted == null) {
      final options = _lengthCounts.keys.toList();
      length = options[_random.nextInt(options.length)];
    } else if (_lengthCounts.containsKey(wanted)) {
      length = wanted;
    } else {
      // The chosen length has no words any more; fall back to the best one.
      length = WordleGame.bestLength(_entries.keys)!;
    }
    _game = WordleGame(
      _entries.keys,
      wordLength: length,
      maxAttempts: WordleSettings.tries,
      random: _random,
    );
  }

  void _type(String letter) {
    final game = _game;
    if (game == null || game.isOver || _current.length >= game.wordLength) return;
    setState(() => _current += letter);
  }

  void _backspace() {
    if (_current.isEmpty || (_game?.isOver ?? true)) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  void _submit() {
    final game = _game;
    if (game == null || game.isOver) return;
    try {
      game.guess(_current);
      setState(() => _current = '');
    } on ArgumentError catch (e) {
      setState(() => _shakeRow = game.guesses.length);
      showMessage(context, e.message.toString());
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _shakeRow = -1);
      });
    }
  }

  void _playAgain() => setState(_newGame);

  void _reload() => setState(() {
        _loaded = false;
        _game = null;
        _load = _repo.fetchAll();
      });

  Future<void> _openSettings() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _SettingsSheet(lengthCounts: _lengthCounts),
    );
    if (changed == true && mounted) {
      setState(_newGame);
      final len = WordleSettings.length;
      showMessage(
        context,
        'New game: ${len == null ? 'random length' : '$len letters'}, '
        '${WordleSettings.tries} tries',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WORDLE'),
        actions: [
          IconButton(
            tooltip: 'How to play',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showHelp,
          ),
          IconButton(
            tooltip: 'Game settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _lengthCounts.isEmpty ? null : _openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<List<WordEntry>>(
        future: _load,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EmptyState(
              title: 'COULDN’T LOAD WORDS',
              message: 'Check your internet connection and try again.',
              actionLabel: 'TRY AGAIN',
              onAction: _reload,
            );
          }
          if (!_loaded) {
            _setup(snap.data ?? const []);
            // Enable the settings button now that word lengths are known.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }
          final game = _game;
          if (game == null) {
            return EmptyState(
              title: 'NO WORDS TO PLAY',
              message: 'Wordle needs words of 3–10 letters from your dictionary. '
                  'Add a few and come back!',
              actionLabel: 'ADD A WORD',
              onAction: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const NewWordPage()))
                  .then((_) => _reload()),
            );
          }
          return _board(game);
        },
      ),
    );
  }

  Widget _board(WordleGame game) {
    final keyColors = game.keyboard.map((k, v) => MapEntry(k, _color(v)));
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) => handleGameKey(
        e,
        onLetter: _type,
        onEnter: _submit,
        onBackspace: _backspace,
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(builder: (context, c) {
          return CenteredScroll(
            maxWidth: 560,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      TagPill('${game.wordLength} letters', color: Colors.white),
                      TagPill('${game.maxAttempts} tries', color: Colors.white),
                      if (WordleSettings.length == null) const TagPill('Random length', color: WW.yellowSoft),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _grid(game, c.maxWidth),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: game.isOver
                        ? GameResultCard(
                            key: const ValueKey('result'),
                            won: game.isWon,
                            word: game.target,
                            entry: _entries[game.target],
                            onPlayAgain: _playAgain,
                          )
                        : LetterKeyboard(
                            key: const ValueKey('keys'),
                            onLetter: _type,
                            onEnter: _submit,
                            onBackspace: _backspace,
                            keyColors: keyColors,
                          ),
                  ),
                ],
              ),
          );
        }),
      ),
    );
  }

  Widget _grid(WordleGame game, double maxWidth) {
    final n = game.wordLength;
    final gap = n > 7 ? 4.0 : 6.0;
    final available = maxWidth.clamp(0.0, 560.0) - 32;
    final tile = ((available - gap * (n - 1)) / n).clamp(24.0, 58.0);

    final rows = <Widget>[];
    for (var r = 0; r < game.maxAttempts; r++) {
      String letters;
      List<LetterResult>? results;
      if (r < game.guesses.length) {
        letters = game.guesses[r];
        results = game.results[r];
      } else if (r == game.guesses.length && !game.isOver) {
        letters = _current;
      } else {
        letters = '';
      }

      final row = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) SizedBox(width: gap),
            _Tile(
              size: tile,
              letter: i < letters.length ? letters[i] : '',
              result: results?[i],
            ),
          ],
        ],
      );

      rows.add(Padding(
        padding: EdgeInsets.only(bottom: gap),
        child: _Shake(active: r == _shakeRow, child: row),
      ));
    }
    return Semantics(
      label: '${game.guesses.length} of ${game.maxAttempts} guesses used',
      child: Column(children: rows),
    );
  }

  Color _color(LetterResult r) {
    switch (r) {
      case LetterResult.correct:
        return WW.correct;
      case LetterResult.present:
        return WW.present;
      case LetterResult.absent:
        return WW.absent;
    }
  }

  void _showHelp() {
    final tries = _game?.maxAttempts ?? WordleSettings.tries;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HOW TO PLAY', style: displayStyle(32)),
              const SizedBox(height: 10),
              Text(
                'Guess the hidden word in $tries tries. After each guess the tiles change colour:',
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 14),
              _helpRow(WW.correct, 'Right letter, right spot'),
              _helpRow(WW.present, 'In the word, wrong spot'),
              _helpRow(WW.absent, 'Not in the word'),
              const SizedBox(height: 6),
              const Text(
                'Tap the settings button to change the word length or number of tries.',
                style: TextStyle(color: WW.muted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpRow(Color color, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

/// Bottom sheet for choosing word length and number of tries.
/// Returns true when the player taps "Start new game".
class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.lengthCounts});

  final Map<int, int> lengthCounts;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late int? _length = WordleSettings.length;
  late int _tries = WordleSettings.tries;

  @override
  Widget build(BuildContext context) {
    final lengths = widget.lengthCounts.keys.toList()..sort();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('GAME SETTINGS', style: displayStyle(32)),
            const SizedBox(height: 18),
            const Text('Word length', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Only lengths that have words in your dictionary are shown.',
              style: TextStyle(color: WW.muted, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.shuffle_rounded, size: 18),
                  label: const Text('Random'),
                  selected: _length == null,
                  onSelected: (_) => setState(() => _length = null),
                ),
                for (final l in lengths)
                  ChoiceChip(
                    label: Text('$l letters  ·  ${widget.lengthCounts[l]}'),
                    selected: _length == l,
                    onSelected: (_) => setState(() => _length = l),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Tries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text('$_tries', style: displayStyle(30)),
              ],
            ),
            Slider(
              value: _tries.toDouble(),
              min: WordleSettings.minTries.toDouble(),
              max: WordleSettings.maxTries.toDouble(),
              divisions: WordleSettings.maxTries - WordleSettings.minTries,
              label: '$_tries tries',
              activeColor: WW.navy,
              onChanged: (v) => setState(() => _tries = v.round()),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Harder', style: TextStyle(color: WW.muted, fontSize: 13)),
                Text('Easier', style: TextStyle(color: WW.muted, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 24),
            ArrowButton(
              label: 'START NEW GAME',
              expand: true,
              onPressed: () {
                WordleSettings.length = _length;
                WordleSettings.tries = _tries;
                Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.size, required this.letter, this.result});

  final double size;
  final String letter;
  final LetterResult? result;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    switch (result) {
      case LetterResult.correct:
        bg = WW.correct;
        break;
      case LetterResult.present:
        bg = WW.present;
        break;
      case LetterResult.absent:
        bg = WW.absent;
        break;
      case null:
        bg = Colors.white;
    }
    final filled = letter.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size > 40 ? 12 : 8),
        border: Border.all(
          color: result != null ? bg : (filled ? WW.navy : WW.outline),
          width: 2,
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.48,
          fontWeight: FontWeight.w800,
          color: result != null ? Colors.white : WW.navy,
        ),
      ),
    );
  }
}

/// Small horizontal shake used when a guess is rejected.
class _Shake extends StatelessWidget {
  const _Shake({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(active),
      tween: Tween(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 400),
      builder: (context, t, child) {
        final dx = active ? 8 * (1 - t) * ((t * 10).floor().isEven ? 1 : -1) : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}
