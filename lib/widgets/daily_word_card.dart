import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/word_entry.dart';
import '../pages/our_dictionary_page.dart';
import '../services/daily_word_service.dart';
import '../services/words.dart';
import '../theme.dart';
import 'common.dart';

/// "Word of the day" card for the home screen.
class DailyWordCard extends StatefulWidget {
  const DailyWordCard({super.key});

  @override
  State<DailyWordCard> createState() => _DailyWordCardState();
}

class _DailyWordCardState extends State<DailyWordCard> {
  final _service = DailyWordService();
  final _repo = WordRepository();
  late final Future<DailyWord> _future = _service.today();
  bool _saving = false;
  bool _saved = false;

  Future<void> _save(DailyWord w) async {
    setState(() => _saving = true);
    try {
      final already = await _repo.exists(w.word, w.type);
      if (!already) {
        await _repo.addWord(WordEntry(
          word: w.word,
          type: w.type,
          meaning: w.meaning,
          sentence: w.message,
        ));
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      showMessage(
        context,
        already ? '“${w.word}” is already in the dictionary' : '“${w.word}” saved to the dictionary',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Couldn’t save the word. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DailyWord>(
      future: _future,
      builder: (context, snap) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: snap.hasData ? _content(snap.data!) : _loading(),
        );
      },
    );
  }

  Widget _label() => Row(
        children: [
          const Sparkle(size: 16, color: Color(0xFFF5C83D)),
          const SizedBox(width: 8),
          Text('WORD OF THE DAY', style: displayStyle(20)),
        ],
      );

  Widget _loading() {
    return WWCard(
      key: const ValueKey('loading'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(),
          const SizedBox(height: 18),
          const Row(
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)),
              SizedBox(width: 12),
              Text('Finding today’s word…', style: TextStyle(color: WW.muted)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _content(DailyWord w) {
    return WWCard(
      key: const ValueKey('content'),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(w.word.toUpperCase(), style: displayStyle(46)),
              if (w.type.isNotEmpty) TagPill(w.type, color: WW.yellowSoft),
            ],
          ),
          const SizedBox(height: 4),
          Text(w.meaning, style: const TextStyle(fontSize: 15.5, color: WW.muted, height: 1.4)),
          if (w.inDictionary) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.auto_stories_rounded, size: 16, color: WW.muted),
                SizedBox(width: 6),
                Text('From your dictionary', style: TextStyle(fontSize: 13, color: WW.muted)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: WW.sky,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              w.message,
              style: const TextStyle(
                fontSize: 17,
                height: 1.55,
                fontStyle: FontStyle.italic,
                color: WW.navy,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => Share.share(w.toShareText()),
                icon: const Icon(Icons.ios_share_rounded, size: 20),
                label: const Text('Share'),
              ),
              if (w.inDictionary)
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WordDetailPage(entry: w.toEntry())),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 20),
                  label: const Text('Open word'),
                )
              else
              OutlinedButton.icon(
                onPressed: _saving || _saved ? null : () => _save(w),
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                    : Icon(_saved ? Icons.check_rounded : Icons.bookmark_add_outlined, size: 20),
                label: Text(_saved ? 'Saved' : 'Save to dictionary'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
