import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'loginpage.dart';
import 'signuppage.dart';

/// First screen for signed-out users — the app version of the landing page.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WWBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              return wide ? _wide(context, constraints) : _narrow(context, constraints);
            },
          ),
        ),
      ),
    );
  }

  Widget _headline(double size, TextAlign align) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'LEARN A NEW WORD.\n', style: displayStyle(size)),
        TextSpan(text: 'MAKE IT YOURS.', style: displayStyle(size, color: WW.blue)),
      ]),
      textAlign: align,
    );
  }

  static const _body =
      'Look up any word in seconds. Save it to a dictionary you build together. '
      'Then play Hangaroo and Wordle — and watch it stick.';

  Widget _buttons(BuildContext context, {required bool expand}) {
    return Column(
      crossAxisAlignment: expand ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ArrowButton(
          label: 'START LEARNING',
          expand: expand,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SignupPage()),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          ),
          child: const Text('I already have an account'),
        ),
      ],
    );
  }

  Widget _narrow(BuildContext context, BoxConstraints c) {
    final headline = (c.maxWidth * 0.14).clamp(44.0, 72.0);
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: c.maxHeight),
        child: IntrinsicHeight(
          child: Column(
            children: [
              const SizedBox(height: 28),
              const WordWiserLogo(size: 38),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                child: Column(
                  children: [
                    _headline(headline, TextAlign.center),
                    const SizedBox(height: 18),
                    const Text(
                      _body,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.5, height: 1.6),
                    ),
                    const SizedBox(height: 28),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _buttons(context, expand: true),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(height: 24),
              Image.asset(
                penguinAsset,
                width: (c.maxWidth * 0.78).clamp(220.0, 420.0),
                excludeFromSemantics: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wide(BuildContext context, BoxConstraints c) {
    return Column(
      children: [
        const SizedBox(height: 32),
        const WordWiserLogo(size: 44),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(72, 24, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headline((c.maxWidth * 0.065).clamp(64.0, 104.0), TextAlign.left),
                      const SizedBox(height: 28),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: const Text(_body, style: TextStyle(fontSize: 19, height: 1.7)),
                      ),
                      const SizedBox(height: 36),
                      _buttons(context, expand: false),
                    ],
                  ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    penguinAsset,
                    width: (c.maxWidth * 0.36).clamp(320.0, 560.0),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
