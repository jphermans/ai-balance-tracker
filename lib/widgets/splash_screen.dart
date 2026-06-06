import 'dart:math';
import 'package:flutter/material.dart';

/// Flutter splash screen matching the native launch screen design.
/// Shown after native splash to extend the branded experience.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Hold for 2.5 seconds total then call onDone
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortest = min(size.width, size.height);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0F23), // deep navy
              Color(0xFF1E285A), // royal blue
              Color(0xFF32468C), // violet blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Tech grid overlay
            CustomPaint(
              size: size,
              painter: _GridPainter(),
            ),
            // Centered content
            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Card icon
                      _buildCardIcon(shortest * 0.35, shortest * 0.24),
                      const SizedBox(height: 32),
                      // App name
                      Text(
                        'AI Balance',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: shortest * 0.07,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tracker',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: shortest * 0.045,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Version at bottom
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Text(
                  'v1.3.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardIcon(double cardW, double cardH) {
    final cc = cardW * 0.14;
    final sh = cardH * 0.30;
    final ss = cardH * 0.28;

    return SizedBox(
      width: cardW + 12,
      height: cardH + 12,
      child: CustomPaint(
        painter: _CardIconPainter(
          cardW: cardW,
          cardH: cardH,
          cornerRadius: cc,
          stripHeight: sh,
          sparkleSize: ss,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    final step = size.width / 6;
    for (var i = 0; i <= size.width / step; i++) {
      canvas.drawLine(Offset(i * step, 0), Offset(i * step, size.height), paint);
      canvas.drawLine(Offset(0, i * step), Offset(size.width, i * step), paint);
    }

    // Glow nodes
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06);
    for (var i = 1; i < size.width / step; i++) {
      for (var j = 1; j < size.height / step; j++) {
        canvas.drawCircle(Offset(i * step, j * step), step * 0.04, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardIconPainter extends CustomPainter {
  final double cardW;
  final double cardH;
  final double cornerRadius;
  final double stripHeight;
  final double sparkleSize;

  _CardIconPainter({
    required this.cardW,
    required this.cardH,
    required this.cornerRadius,
    required this.stripHeight,
    required this.sparkleSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = (size.width - cardW) / 2;
    final cy = (size.height - cardH) / 2;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx, cy, cardW, cardH),
      Radius.circular(cornerRadius),
    );

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      cardRect.shift(const Offset(0, 4)),
      shadowPaint,
    );

    // Card body
    final cardPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawRRect(cardRect, cardPaint);

    // Top accent strip
    final stripPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx, cy, cardW, stripHeight + cornerRadius),
        Radius.circular(cornerRadius),
      ));
    // Clip bottom of strip to be flat
    stripPath.addRect(Rect.fromLTWH(cx, cy + stripHeight, cardW, cornerRadius));
    canvas.drawPath(
      stripPath,
      Paint()..color = const Color(0xFF4F46E5).withValues(alpha: 0.92),
    );

    // Strip gradient overlay
    final stripGrad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4F46E5).withValues(alpha: 0.95),
          const Color(0xFF8B5CF6).withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(cx, cy, cardW, stripHeight));
    canvas.drawRect(Rect.fromLTWH(cx, cy, cardW, stripHeight), stripGrad);

    // Dots on strip
    final dotPaint = Paint()..color = Colors.white;
    for (var i = 0; i < 3; i++) {
      final dx = cx + cardW * 0.2 + i * cardW * 0.15;
      final dy = cy + stripHeight / 2;
      canvas.drawCircle(
        Offset(dx, dy),
        stripHeight * 0.15,
        dotPaint..color = Colors.white.withValues(alpha: 0.8 - i * 0.08),
      );
    }

    // AI Sparkle (4-point star)
    final scx = cx + cardW / 2;
    final scy = cy + stripHeight + (cardH - stripHeight) / 2;
    final starPaint = Paint()..style = PaintingStyle.fill;

    // Outer glow
    canvas.drawCircle(
      Offset(scx, scy),
      sparkleSize * 0.7,
      Paint()
        ..color = const Color(0xFF6366F1).withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Star
    final starPath = Path();
    for (var i = 0; i < 4; i++) {
      final a = i * pi / 2 - pi / 2;
      final ox = scx + sparkleSize * cos(a);
      final oy = scy + sparkleSize * sin(a);
      final ix = scx + sparkleSize * 0.35 * cos(a + pi / 4);
      final iy = scy + sparkleSize * 0.35 * sin(a + pi / 4);
      if (i == 0) {
        starPath.moveTo(ox, oy);
      } else {
        starPath.lineTo(ox, oy);
      }
      starPath.lineTo(ix, iy);
    }
    starPath.close();
    canvas.drawPath(starPath, Paint()..color = const Color(0xFF4F46E5));

    // Inner star highlight
    final innerPath = Path();
    for (var i = 0; i < 4; i++) {
      final a = i * pi / 2 - pi / 2;
      final ox = scx + sparkleSize * 0.55 * cos(a);
      final oy = scy + sparkleSize * 0.55 * sin(a);
      final ix = scx + sparkleSize * 0.25 * cos(a + pi / 4);
      final iy = scy + sparkleSize * 0.25 * sin(a + pi / 4);
      if (i == 0) {
        innerPath.moveTo(ox, oy);
      } else {
        innerPath.lineTo(ox, oy);
      }
      innerPath.lineTo(ix, iy);
    }
    innerPath.close();
    canvas.drawPath(
        innerPath, Paint()..color = const Color(0xFF8B5CF6).withValues(alpha: 0.7));

    // Center dot
    canvas.drawCircle(
      Offset(scx, scy),
      sparkleSize * 0.13,
      Paint()..color = Colors.white,
    );

    // Balance bars
    final barY = scy + sparkleSize * 0.75;
    final barFullW = cardW * 0.38;
    final barX = scx - barFullW / 2;
    final barGap = sparkleSize * 0.26;
    final barColors = [
      const Color(0xFF4F46E5),
      const Color(0xFF6366F1),
      const Color(0xFFA5B4FC),
    ];
    for (var i = 0; i < 3; i++) {
      final bw = barFullW - i * barFullW * 0.24;
      final by = barY + i * barGap;
      final bh = barGap * 0.55;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barX + (barFullW - bw) / 2, by, bw, bh),
        Radius.circular(bh * 0.45),
      );
      canvas.drawRRect(
        barRect,
        Paint()..color = barColors[i].withValues(alpha: 0.8 - i * 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
