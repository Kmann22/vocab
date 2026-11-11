import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

const penguinAsset = 'assets/images/penguin.png';

/// Light-blue page with the soft flower shapes from the landing page.
class WWBackground extends StatelessWidget {
  const WWBackground({super.key, required this.child, this.showFlowers = true});

  final Widget child;
  final bool showFlowers;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WW.background,
      child: Stack(
        children: [
          if (showFlowers) ...const [
            Positioned(left: -60, top: -70, child: Flower(size: 190, color: WW.flower)),
            Positioned(right: -70, top: 220, child: Flower(size: 200, color: WW.yellowSoft)),
            Positioned(left: -50, bottom: -60, child: Flower(size: 200, color: WW.flower)),
          ],
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// A soft six-petal flower used as decoration.
class Flower extends StatelessWidget {
  const Flower({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _FlowerPainter(color)),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  _FlowerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * 0.48, r * 0.34, paint);
    }
    canvas.drawCircle(c, r * 0.5, paint);
  }

  @override
  bool shouldRepaint(_FlowerPainter old) => old.color != color;
}

/// Four-point sparkle.
class Sparkle extends StatelessWidget {
  const Sparkle({super.key, this.size = 18, this.color = WW.yellow});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _SparklePainter(color)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..quadraticBezierTo(w * 0.55, h * 0.45, w, h / 2)
      ..quadraticBezierTo(w * 0.55, h * 0.55, w / 2, h)
      ..quadraticBezierTo(w * 0.45, h * 0.55, 0, h / 2)
      ..quadraticBezierTo(w * 0.45, h * 0.45, w / 2, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

/// WORD / WISER logo with sparkles and optional tagline.
class WordWiserLogo extends StatelessWidget {
  const WordWiserLogo({super.key, this.size = 40, this.showTagline = true});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'WordWiser',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Sparkle(size: size * 0.4, color: const Color(0xFFF5C83D)),
              SizedBox(width: size * 0.2),
              Text('WORD\nWISER', textAlign: TextAlign.center, style: logoStyle(size)),
              SizedBox(width: size * 0.2),
              Sparkle(size: size * 0.55, color: const Color(0xFFF5C83D)),
            ],
          ),
          if (showTagline) ...[
            SizedBox(height: size * 0.25),
            Text(
              'BUILD YOUR VOCABULARY',
              style: TextStyle(
                fontSize: math.max(11.0, size * 0.28),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
                color: WW.navy,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// White rounded card used across the app.
class WWCard extends StatelessWidget {
  const WWCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
    this.onTap,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: Colors.white, width: 2),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: WW.shadow,
      ),
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Yellow pill button with a trailing arrow and built-in loading state.
class ArrowButton extends StatelessWidget {
  const ArrowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 24),
          if (loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          else
            const Icon(Icons.arrow_forward_rounded, size: 22),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Friendly empty / error state with the penguin.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showPenguin = true,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showPenguin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showPenguin) ...[
                Image.asset(penguinAsset, height: 150, excludeFromSemantics: true),
                const SizedBox(height: 16),
              ],
              Text(title, textAlign: TextAlign.center, style: displayStyle(34)),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.5, color: WW.muted),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                ArrowButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded label, e.g. a word type.
class TagPill extends StatelessWidget {
  const TagPill(this.text, {super.key, this.color = WW.sky});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: WW.outline),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WW.navy),
      ),
    );
  }
}

/// Centres content and caps its width so pages look right on tablets and web.
class Constrained extends StatelessWidget {
  const Constrained({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Centres its child horizontally AND vertically when it fits on screen, and
/// scrolls normally when it's taller than the screen (small phones,
/// landscape, big text sizes).
class CenteredScroll extends StatelessWidget {
  const CenteredScroll({
    super.key,
    required this.child,
    this.maxWidth = 560,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0.0, c.maxHeight - padding.vertical),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      );
    });
  }
}

void showMessage(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}
