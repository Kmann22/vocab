import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocab/pages/hangaroo_game.dart';
import 'package:vocab/models/word_entry.dart';
import 'package:vocab/services/daily_word_service.dart';
import 'package:vocab/pages/wordle_game.dart';

void main() {
  group('Wordle scoring', () {
    const c = LetterResult.correct, p = LetterResult.present, a = LetterResult.absent;

    test('exact match is all correct', () {
      expect(WordleGame.evaluate('APPLE', 'APPLE'), [c, c, c, c, c]);
    });

    test('repeated letter only counts as many times as it appears', () {
      // Target has one E; guess has two. Only the first extra E is yellow.
      expect(WordleGame.evaluate('EERIE', 'THERE'), [p, a, p, a, c]);
    });

    test('green takes priority over yellow for the same letter', () {
      expect(WordleGame.evaluate('LLAMA', 'HELLO'), [p, p, a, a, a]);
      expect(WordleGame.evaluate('SPEED', 'ABIDE'), [a, a, p, a, p]);
    });

    test('guess validation gives friendly errors', () {
      final g = WordleGame(['apple', 'grape'], wordLength: 5, random: Random(1));
      expect(() => g.guess('abc'), throwsArgumentError);
      expect(() => g.guess('ab1de'), throwsArgumentError);
      g.guess('zzzzz');
      expect(() => g.guess('zzzzz'), throwsArgumentError);
    });

    test('bestLength prefers 5, else the most common length', () {
      expect(WordleGame.bestLength(['apple', 'cat', 'banana']), 5);
      expect(WordleGame.bestLength(['tree', 'frog', 'banana']), 4);
      expect(WordleGame.bestLength(['ox', 'a b c']), isNull);
    });

    test('lengthCounts covers 3 to 10 letters and ignores the rest', () {
      expect(
        WordleGame.lengthCounts(['cat', 'dog', 'kangaroos', 'ox', 'extraordinary', 'ice cream']),
        {3: 2, 9: 1},
      );
    });

    test('works with long words and custom tries', () {
      final g = WordleGame(['vocabulary'], wordLength: 10, maxAttempts: 3);
      g.guess('aaaaaaaaaa');
      g.guess('bbbbbbbbbb');
      g.guess('vocabulary');
      expect(g.isWon, isTrue);
    });

    test('game ends after six wrong guesses', () {
      final g = WordleGame(['apple'], wordLength: 5);
      for (final w in ['aaaaa', 'bbbbb', 'ccccc', 'ddddd', 'eeeee', 'fffff']) {
        g.guess(w);
      }
      expect(g.isOver, isTrue);
      expect(g.isWon, isFalse);
    });
  });

  group('Hangaroo', () {
    test('filters out words it cannot play', () {
      expect(
        HangarooGame.playableWords(['ice cream', 'up', "don't", 'Kangaroo', 'well-being']),
        ['KANGAROO'],
      );
    });

    test('win and lose', () {
      final win = HangarooGame(['cat']);
      for (final l in ['C', 'A', 'T']) {
        win.guess(l);
      }
      expect(win.isWon, isTrue);

      final lose = HangarooGame(['cat'], maxMistakes: 2);
      lose.guess('X');
      lose.guess('Y');
      expect(lose.isLost, isTrue);
      expect(lose.revealed.join(), 'CAT');
    });

    test('repeating a letter does not cost a try', () {
      final g = HangarooGame(['cat']);
      g.guess('Z');
      g.guess('Z');
      expect(g.mistakes, 1);
    });
  });

  group('Word of the day', () {
    final words = [
      const WordEntry(id: 'a', word: 'Bliss', type: 'noun', meaning: 'Perfect happiness'),
      const WordEntry(id: 'b', word: 'Shine', type: 'verb', meaning: 'To give out light'),
      const WordEntry(id: 'c', word: 'Brave', type: 'adjective', meaning: 'Ready to face danger'),
    ];

    test('picks the same dictionary word all day', () {
      final morning = DailyWordService.pickForDate(words, DateTime(2026, 11, 10, 7));
      final night = DailyWordService.pickForDate(words.reversed.toList(), DateTime(2026, 11, 10, 23));
      expect(morning.id, night.id);
    });

    test('skips recently used words when it can', () {
      final pick = DailyWordService.pickForDate(words, DateTime(2026, 11, 10), recent: ['Bliss', 'Shine']);
      expect(pick.word, 'Brave');
    });

    test('cleans the AI message and requires the word', () {
      expect(DailyWordService.cleanMessage('"May today bring you bliss."', 'Bliss'), 'May today bring you bliss.');
      expect(DailyWordService.cleanMessage('Have a lovely day!', 'Bliss'), isNull);
      expect(DailyWordService.cleanMessage('', 'Bliss'), isNull);
    });

    test('template message always uses the word', () {
      final m = DailyWordService.templateMessage('Bliss', 'Perfect happiness', DateTime(2026, 11, 10));
      expect(m.contains('Bliss'), isTrue);
    });

    test('built-in fallback is the same all day', () {
      final a = DailyWordService.fallbackFor(DateTime(2026, 11, 10, 8));
      final b = DailyWordService.fallbackFor(DateTime(2026, 11, 10, 22));
      expect(a.word, b.word);
      expect(a.inDictionary, isFalse);
    });
  });
}
