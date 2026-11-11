import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/word_entry.dart';
import '../services/words.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'add_new_word.dart';

class OurDictionary extends StatefulWidget {
  const OurDictionary({super.key});

  @override
  State<OurDictionary> createState() => _OurDictionaryState();
}

class _OurDictionaryState extends State<OurDictionary> {
  final _repo = WordRepository();
  final _search = TextEditingController();
  late final Stream<List<WordEntry>> _words = _repo.watchAll();
  late final Stream<Set<String>> _favourites = _repo.watchFavouriteIds();

  String _query = '';
  bool _favouritesOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggleFavourite(WordEntry entry, bool favourite) async {
    try {
      await _repo.setFavourite(entry, favourite);
      if (!mounted) return;
      showMessage(
        context,
        favourite ? '“${entry.word}” added to favourites' : '“${entry.word}” removed from favourites',
      );
    } catch (_) {
      if (mounted) showMessage(context, 'Couldn’t update favourites. Try again.');
    }
  }

  List<WordEntry> _filter(List<WordEntry> words, Set<String> favs) {
    final q = _query.trim().toLowerCase();
    return words.where((w) {
      if (_favouritesOnly && !favs.contains(w.id)) return false;
      if (q.isEmpty) return true;
      return w.word.toLowerCase().contains(q) || w.meaning.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OUR DICTIONARY')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewWordPage()),
        ),
        backgroundColor: WW.yellow,
        foregroundColor: WW.navy,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add word', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<WordEntry>>(
        stream: _words,
        builder: (context, wordSnap) {
          return StreamBuilder<Set<String>>(
            stream: _favourites,
            builder: (context, favSnap) {
              if (wordSnap.hasError) {
                return const EmptyState(
                  title: 'COULDN’T LOAD WORDS',
                  message: 'Check your internet connection and try again.',
                );
              }
              if (!wordSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = wordSnap.data!;
              final favs = favSnap.data ?? const <String>{};
              if (all.isEmpty) {
                return EmptyState(
                  title: 'NO WORDS YET',
                  message: 'Be the first to add a word to the dictionary.',
                  actionLabel: 'ADD A WORD',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NewWordPage()),
                  ),
                );
              }
              final words = _filter(all, favs);
              return _buildList(words, favs, all.length);
            },
          );
        },
      ),
    );
  }

  Widget _buildList(List<WordEntry> words, Set<String> favs, int total) {
    // Flatten into letter headers + word rows so the list can be built lazily
    // (only what's on screen is drawn, so long dictionaries stay smooth).
    final items = <Object>[];
    String? lastInitial;
    for (final w in words) {
      if (w.initial != lastInitial) {
        lastInitial = w.initial;
        items.add(w.initial);
      }
      items.add(w);
    }

    return LayoutBuilder(builder: (context, c) {
      final side = c.maxWidth > 760 ? (c.maxWidth - 720) / 2 : 20.0;
      return CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(side, 4, side, 0),
            sliver: SliverToBoxAdapter(child: _header(words.isEmpty, favs, total)),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(side, 0, side, 100),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                    child: Text(item, style: displayStyle(30, color: WW.blue)),
                  );
                }
                final w = item as WordEntry;
                final isFav = favs.contains(w.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WordRow(
                    entry: w,
                    favourite: isFav,
                    onFavourite: () => _toggleFavourite(w, !isFav),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => WordDetailPage(entry: w)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _header(bool noResults, Set<String> favs, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search $total words',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All words'),
              selected: !_favouritesOnly,
              onSelected: (_) => setState(() => _favouritesOnly = false),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.favorite_rounded, size: 18),
              label: Text('Favourites (${favs.length})'),
              selected: _favouritesOnly,
              onSelected: (_) => setState(() => _favouritesOnly = true),
            ),
          ],
        ),
        if (noResults)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 48, 12, 0),
            child: Column(
              children: [
                Text(
                  _favouritesOnly && _query.isEmpty ? 'NO FAVOURITES YET' : 'NO MATCHES',
                  textAlign: TextAlign.center,
                  style: displayStyle(32),
                ),
                const SizedBox(height: 8),
                Text(
                  _favouritesOnly && _query.isEmpty
                      ? 'Tap the heart on any word to save it here.'
                      : 'Nothing matches “${_query.trim()}”. Try another spelling.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: WW.muted, height: 1.5),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.entry,
    required this.favourite,
    required this.onFavourite,
    required this.onTap,
  });

  final WordEntry entry;
  final bool favourite;
  final VoidCallback onFavourite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WWCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(18, 14, 6, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(entry.word, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    if (entry.type.isNotEmpty) TagPill(entry.type),
                  ],
                ),
                if (entry.meaning.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.meaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: WW.muted, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: favourite ? 'Remove from favourites' : 'Add to favourites',
            onPressed: onFavourite,
            icon: Icon(
              favourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favourite ? const Color(0xFFD9485F) : WW.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class WordDetailPage extends StatefulWidget {
  const WordDetailPage({super.key, required this.entry});

  final WordEntry entry;

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
  final _repo = WordRepository();
  late final Stream<Set<String>> _favourites = _repo.watchFavouriteIds();

  WordEntry get e => widget.entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WORD'),
        actions: [
          StreamBuilder<Set<String>>(
            stream: _favourites,
            builder: (context, snap) {
              final fav = snap.data?.contains(e.id) ?? false;
              return IconButton(
                tooltip: fav ? 'Remove from favourites' : 'Add to favourites',
                icon: Icon(
                  fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: fav ? const Color(0xFFD9485F) : WW.navy,
                ),
                onPressed: () async {
                  try {
                    await _repo.setFavourite(e, !fav);
                  } catch (_) {
                    if (context.mounted) showMessage(context, 'Couldn’t update favourites.');
                  }
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => Share.share(e.toShareText()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Constrained(
              maxWidth: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(e.word.toUpperCase(), style: displayStyle(60)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (e.type.isNotEmpty) TagPill(e.type, color: WW.yellowSoft),
                      if (e.pronunciation.isNotEmpty)
                        Text(e.pronunciation, style: const TextStyle(fontSize: 17, color: WW.muted)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _Section(
                    title: 'Meaning',
                    child: Text(e.meaning, style: const TextStyle(fontSize: 18, height: 1.55)),
                  ),
                  if (e.sentence.isNotEmpty)
                    _Section(
                      title: 'Example',
                      child: Text(
                        '“${e.sentence}”',
                        style: const TextStyle(fontSize: 17, height: 1.55, fontStyle: FontStyle.italic),
                      ),
                    ),
                  if (e.synonyms.isNotEmpty)
                    _Section(title: 'Synonyms', child: _chips(e.synonyms)),
                  if (e.antonyms.isNotEmpty)
                    _Section(title: 'Antonyms', child: _chips(e.antonyms)),
                  if ((e.addedBy ?? '').isNotEmpty && e.addedBy != 'Anonymous')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Added by ${e.addedBy}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: WW.muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips(List<String> items) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final s in items) TagPill(s)],
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: WWCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: displayStyle(24, color: WW.blue)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
