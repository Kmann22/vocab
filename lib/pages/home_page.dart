import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/authentication.dart';
import '../services/words.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/daily_word_card.dart';
import 'add_new_word.dart';
import 'game_hangaroo.dart';
import 'game_wordle.dart';
import 'our_dictionary_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = WordRepository();
  late final Stream<int> _addedCount = _repo.watchAddedCount();

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _firstName {
    final name = _user?.displayName?.trim() ?? '';
    if (name.isEmpty) return 'there';
    return name.split(RegExp(r'\s+')).first;
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can log back in any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true) {
      await AuthService.signOut();
      // AuthGate shows the welcome screen.
    }
  }

  void _showProfile() {
    final user = _user;
    if (user == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _Avatar(name: user.displayName, size: 64)),
              const SizedBox(height: 12),
              Text(
                user.displayName?.isNotEmpty == true ? user.displayName! : 'WordWiser learner',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(user.email ?? '', textAlign: TextAlign.center, style: const TextStyle(color: WW.muted)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _StatTile(label: 'Words added', stream: _repo.watchAddedCount())),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Favourites',
                      stream: _repo.watchFavouriteIds().map((s) => s.length),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmLogout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WWBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 4 : 2;
              final horizontal = constraints.maxWidth >= 600 ? 32.0 : 20.0;
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                    sliver: SliverToBoxAdapter(
                      child: Constrained(
                        maxWidth: 1000,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _topBar(),
                            const SizedBox(height: 20),
                            _greetingCard(constraints.maxWidth),
                            const SizedBox(height: 16),
                            const DailyWordCard(),
                            const SizedBox(height: 28),
                            Text('WHAT WOULD YOU LIKE TO DO?', style: displayStyle(26)),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 32),
                    sliver: SliverToBoxAdapter(
                      child: Constrained(
                        maxWidth: 1000,
                        child: GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            mainAxisExtent: 200,
                          ),
                          children: [
                            _ActionTile(
                              title: 'Add a word',
                              subtitle: 'Look it up and save it',
                              icon: Icons.add_rounded,
                              color: WW.yellow,
                              onTap: () => _open(const NewWordPage()),
                            ),
                            _ActionTile(
                              title: 'Our dictionary',
                              subtitle: 'Browse every saved word',
                              icon: Icons.menu_book_rounded,
                              onTap: () => _open(const OurDictionary()),
                            ),
                            _ActionTile(
                              title: 'Hangaroo',
                              subtitle: 'Guess the word letter by letter',
                              icon: Icons.extension_rounded,
                              onTap: () => _open(const HangarooPage()),
                            ),
                            _ActionTile(
                              title: 'Wordle',
                              subtitle: 'Find the word in six tries',
                              icon: Icons.grid_view_rounded,
                              onTap: () => _open(const WordlePage()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        Tooltip(
          message: 'Your profile',
          child: InkResponse(
            onTap: _showProfile,
            radius: 28,
            child: _Avatar(name: _user?.displayName, size: 44),
          ),
        ),
        const Expanded(child: Center(child: WordWiserLogo(size: 24, showTagline: false))),
        IconButton(
          tooltip: 'Log out',
          onPressed: _confirmLogout,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.logout_rounded, color: WW.navy),
        ),
      ],
    );
  }

  Widget _greetingCard(double width) {
    final compact = width < 420;
    return WWCard(
      color: WW.sky,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: compact ? 190 : 220,
        child: Stack(
          children: [
            Positioned(
              right: compact ? -14 : 8,
              bottom: 0,
              child: Image.asset(
                penguinAsset,
                height: compact ? 150 : 190,
                excludeFromSemantics: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 0, 22),
              child: FractionallySizedBox(
                widthFactor: compact ? 0.62 : 0.6,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('HI, ${_firstName.toUpperCase()}!', style: displayStyle(compact ? 40 : 52)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ready to learn a new word today?',
                      style: TextStyle(fontSize: compact ? 14.5 : 16, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder<int>(
                      stream: _addedCount,
                      builder: (context, snap) {
                        final n = snap.data ?? 0;
                        return TagPill(
                          n == 1 ? '1 word added' : '$n words added',
                          color: Colors.white,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: WWCard(
        color: color,
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color == Colors.white ? WW.sky : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: WW.navy, size: 26),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, height: 1.35, color: WW.muted),
            ),
            const SizedBox(height: 10),
            const Icon(Icons.arrow_forward_rounded, color: WW.navy, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size});

  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = (name?.trim().isNotEmpty ?? false) ? name!.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: WW.yellow,
      child: Text(
        letter,
        style: logoStyle(size * 0.45),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.stream});

  final String label;
  final Stream<int> stream;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: WW.sky, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snap) => Text('${snap.data ?? '–'}', style: displayStyle(38)),
          ),
          Text(label, style: const TextStyle(color: WW.muted)),
        ],
      ),
    );
  }
}
