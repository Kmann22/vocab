import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/word_entry.dart';
import '../theme.dart';
import 'common.dart';

/// On-screen QWERTY keyboard shared by both games.
class LetterKeyboard extends StatelessWidget {
  const LetterKeyboard({
    super.key,
    required this.onLetter,
    this.keyColors = const {},
    this.disabled = const {},
    this.onEnter,
    this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onLetter;
  final Map<String, Color> keyColors;
  final Set<String> disabled;
  final VoidCallback? onEnter;
  final VoidCallback? onBackspace;
  final bool enabled;

  static const _rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 6.0;
      final keyW = ((c.maxWidth - gap * 9) / 10).clamp(24.0, 50.0);
      final keyH = (keyW * 1.3).clamp(44.0, 58.0);

      Widget letterKey(String l) {
        final bg = keyColors[l] ?? Colors.white;
        final isDisabled = !enabled || disabled.contains(l);
        final fg = bg == Colors.white ? WW.navy : Colors.white;
        return _Key(
          width: keyW,
          height: keyH,
          color: bg,
          onTap: isDisabled ? null : () => onLetter(l),
          semanticsLabel: l,
          child: Text(l, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fg)),
        );
      }

      final rows = <Widget>[];
      for (var r = 0; r < _rows.length; r++) {
        final keys = <Widget>[];
        if (r == 2 && onEnter != null) {
          keys.add(_Key(
            width: keyW * 1.5 + gap / 2,
            height: keyH,
            color: WW.yellow,
            onTap: enabled ? onEnter : null,
            semanticsLabel: 'Enter',
            child: const Text('ENTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ));
        }
        for (final l in _rows[r].split('')) {
          keys.add(letterKey(l));
        }
        if (r == 2 && onBackspace != null) {
          keys.add(_Key(
            width: keyW * 1.5 + gap / 2,
            height: keyH,
            color: Colors.white,
            onTap: enabled ? onBackspace : null,
            semanticsLabel: 'Delete letter',
            child: const Icon(Icons.backspace_outlined, size: 20, color: WW.navy),
          ));
        }
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: gap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < keys.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                keys[i],
              ],
            ],
          ),
        ));
      }
      return Column(mainAxisSize: MainAxisSize.min, children: rows);
    });
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.width,
    required this.height,
    required this.color,
    required this.child,
    required this.semanticsLabel,
    this.onTap,
  });

  final double width;
  final double height;
  final Color color;
  final Widget child;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final faded = onTap == null && color == Colors.white;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Opacity(
        opacity: faded ? 0.45 : 1,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            child: SizedBox(width: width, height: height, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

/// Card shown when a round ends: result, the word and its meaning.
class GameResultCard extends StatelessWidget {
  const GameResultCard({
    super.key,
    required this.won,
    required this.word,
    required this.onPlayAgain,
    this.entry,
  });

  final bool won;
  final String word;
  final WordEntry? entry;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: WWCard(
        color: won ? const Color(0xFFE3F5EA) : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              won ? 'YOU GOT IT!' : 'SO CLOSE!',
              textAlign: TextAlign.center,
              style: displayStyle(40, color: won ? WW.correct : WW.navy),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'The word was '),
                TextSpan(text: word, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (entry?.type.isNotEmpty ?? false) TextSpan(text: '  (${entry!.type})'),
              ]),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (entry?.meaning.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Text(
                entry!.meaning,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.5, color: WW.muted),
              ),
            ],
            const SizedBox(height: 18),
            Center(child: ArrowButton(label: 'PLAY AGAIN', onPressed: onPlayAgain)),
          ],
        ),
      ),
    );
  }
}

/// Handles physical-keyboard letters, Enter and Backspace for the games.
KeyEventResult handleGameKey(
  KeyEvent event, {
  required ValueChanged<String> onLetter,
  VoidCallback? onEnter,
  VoidCallback? onBackspace,
}) {
  if (event is! KeyDownEvent) return KeyEventResult.ignored;
  final key = event.logicalKey;
  if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
    onEnter?.call();
    return onEnter == null ? KeyEventResult.ignored : KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.backspace) {
    onBackspace?.call();
    return onBackspace == null ? KeyEventResult.ignored : KeyEventResult.handled;
  }
  final label = key.keyLabel.toUpperCase();
  if (label.length == 1 && RegExp('[A-Z]').hasMatch(label)) {
    onLetter(label);
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}
