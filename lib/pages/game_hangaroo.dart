import 'package:flutter/material.dart';

import '../models/word_entry.dart';
import '../services/words.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_widgets.dart';
import 'add_new_word.dart';
import 'hangaroo_game.dart';

class HangarooPage extends StatefulWidget {
  const HangarooPage({super.key});

  @override
  State<HangarooPage> createState() => _HangarooPageState();
}

class _HangarooPageState extends State<HangarooPage> {
  final _repo = WordRepository();
  late Future<List<WordEntry>> _load = _repo.fetchAll();

  HangarooGame? _game;
  Map<String, WordEntry> _entries = {};
  bool _showHint = false;

  void _setup(List<WordEntry> words) {
    if (_game != null) return;
    _entries = {for (final w in words) w.word.trim().toUpperCase(): w};
    final playable = HangarooGame.playableWords(_entries.keys);
    if (playable.isNotEmpty) _game = HangarooGame(playable);
  }

  void _guess(String letter) {
    final game = _game;
    if (game == null || game.isOver || game.guessedLetters.contains(letter)) return;
    setState(() => game.guess(letter));
  }

  void _restart() => setState(() {
        _game?.reset();
        _showHint = false;
      });

  void _retryLoad() => setState(() => _load = _repo.fetchAll());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HANGAROO')),
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
              onAction: _retryLoad,
            );
          }
          _setup(snap.data ?? const []);
          final game = _game;
          if (game == null) {
            return EmptyState(
              title: 'NO WORDS TO PLAY',
              message: 'Hangaroo uses words from your dictionary. '
                  'Add a few words (letters only, 3+ letters) and come back!',
              actionLabel: 'ADD A WORD',
              onAction: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const NewWordPage()))
                  .then((_) => setState(() {
                        _game = null;
                        _load = _repo.fetchAll();
                      })),
            );
          }
          return _board(game);
        },
      ),
    );
  }

  Widget _board(HangarooGame game) {
    final entry = _entries[game.word];
    final colors = <String, Color>{
      for (final l in game.guessedLetters) l: game.isCorrectLetter(l) ? WW.correct : WW.absent,
    };

    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) => handleGameKey(e, onLetter: _guess),
      child: SafeArea(
        top: false,
        child: CenteredScroll(
          maxWidth: 560,
          child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WWCard(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(
                      children: [
                        _Lives(remaining: game.remainingAttempts, total: game.maxMistakes),
                        const SizedBox(height: 22),
                        _WordSlots(letters: game.revealed, lost: game.isLost, word: game.word),
                        const SizedBox(height: 16),
                        if (!game.isOver && entry != null && entry.meaning.isNotEmpty)
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 250),
                            crossFadeState:
                                _showHint ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            firstChild: TextButton.icon(
                              onPressed: () => setState(() => _showHint = true),
                              icon: const Icon(Icons.lightbulb_outline_rounded),
                              label: const Text('Need a hint?'),
                            ),
                            secondChild: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: WW.sky,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${entry.type.isNotEmpty ? '(${entry.type}) ' : ''}${entry.meaning}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(height: 1.45),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: game.isOver
                        ? GameResultCard(
                            key: const ValueKey('result'),
                            won: game.isWon,
                            word: game.word,
                            entry: entry,
                            onPlayAgain: _restart,
                          )
                        : LetterKeyboard(
                            key: const ValueKey('keys'),
                            onLetter: _guess,
                            keyColors: colors,
                            disabled: game.guessedLetters,
                          ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _Lives extends StatelessWidget {
  const _Lives({required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$remaining of $total tries left',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < total; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedScale(
                    scale: i < remaining ? 1 : 0.8,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      i < remaining ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: i < remaining ? const Color(0xFFD9485F) : WW.outline,
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            remaining == 1 ? '1 try left' : '$remaining tries left',
            style: const TextStyle(color: WW.muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _WordSlots extends StatelessWidget {
  const _WordSlots({required this.letters, required this.lost, required this.word});

  final List<String> letters;
  final bool lost;
  final String word;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 6.0;
      final size = ((c.maxWidth - gap * (letters.length - 1)) / letters.length).clamp(22.0, 46.0);
      return Semantics(
        label: lost
            ? 'The word was $word'
            : 'Word: ${letters.map((l) => l == '_' ? 'blank' : l).join(', ')}',
        excludeSemantics: true,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < letters.length; i++)
              Container(
                width: size,
                height: size * 1.2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: letters[i] == '_' ? WW.sky : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    bottom: BorderSide(
                      color: letters[i] == '_' ? WW.outline : WW.navy,
                      width: 3,
                    ),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                  child: Text(
                    letters[i] == '_' ? '' : letters[i],
                    key: ValueKey('$i${letters[i]}'),
                    style: TextStyle(
                      fontSize: size * 0.55,
                      fontWeight: FontWeight.w800,
                      color: lost ? WW.danger : WW.navy,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
