import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpendOrbCard extends StatefulWidget {
  final double spentToday;
  final double dailyAllowance;
  final List<Map<String, dynamic>> recentExpenses;

  const SpendOrbCard({
    super.key,
    required this.spentToday,
    required this.dailyAllowance,
    required this.recentExpenses,
  });

  @override
  State<SpendOrbCard> createState() => _SpendOrbCardState();
}

class _SpendOrbCardState extends State<SpendOrbCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double ratio = widget.dailyAllowance <= 0
        ? 0
        : (widget.spentToday / widget.dailyAllowance).clamp(0.0, 1.0);

    final chips = widget.recentExpenses.take(3).toList();
    const alignments = [
      Alignment(-0.9, -0.75),
      Alignment(0.9, 0.3),
      Alignment(-0.8, 0.75),
    ];

    return Container(
      height: 290,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF0B1B45),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated orb
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: const Size(240, 240),
              painter: _OrbPainter(_controller.value, ratio),
            ),
          ),

          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SPENT TODAY',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: widget.spentToday),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '₹${value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.dailyAllowance > 0
                      ? 'Daily allowance ₹${widget.dailyAllowance.toStringAsFixed(0)}'
                      : 'Set a budget to see your limit',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // Floating chips
          for (int i = 0; i < chips.length; i++)
            _floatingChip(i, chips[i], alignments[i]),

          if (chips.isEmpty)
            Align(
              alignment: const Alignment(0, 0.9),
              child: Text(
                'No spending yet today',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _floatingChip(
    int index,
    Map<String, dynamic> tx,
    Alignment alignment,
  ) {
    return AnimatedBuilder(
      animation: _controller,
      child: _chip(tx),
      builder: (context, child) {
        final double dy =
            math.sin(_controller.value * 2 * math.pi * 3 + index * 1.7) * 6;
        return Align(
          alignment: alignment,
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
    );
  }

  Widget _chip(Map<String, dynamic> tx) {
    final double amount = (tx['amount'] as double).abs();

    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF14213D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tx['color'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              tx['icon'] as IconData,
              size: 16,
              color: tx['iconColor'] as Color,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx['name'] as String,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '-₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t; // 0..1 animation progress
  final double intensity; // 0..1 based on spending vs daily allowance

  _OrbPainter(this.t, this.intensity);

  // Navy palette
  static const Color navyDeep = Color(0xFF050B1F);
  static const Color navyCore = Color(0xFF0A1433);
  static const Color navyBlue = Color(0xFF1E3A8A);
  static const Color navyBright = Color(0xFF3151B8);
  static const Color navyRim = Color(0xFF3B5BDB);
  static const Color navySpark = Color(0xFF93A8E8);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide * 0.36;
    final double breathe = 1 + 0.025 * math.sin(t * 2 * math.pi * 2);
    final double rr = r * breathe;

    // 1. Outer glow (navy)
    canvas.drawCircle(
      c,
      rr * 1.7,
      Paint()
        ..shader = RadialGradient(colors: [
          navyBlue.withOpacity(0.3 + 0.3 * intensity),
          navyBlue.withOpacity(0),
        ]).createShader(Rect.fromCircle(center: c, radius: rr * 1.7)),
    );

    // 2. Sphere body (deep navy core, lighter navy edge)
    final Rect sphereRect = Rect.fromCircle(center: c, radius: rr);
    canvas.drawCircle(
      c,
      rr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          radius: 0.95,
          colors: [
            navyCore,
            navyDeep,
            Color.lerp(navyBlue, navyBright, intensity)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(sphereRect),
    );

    // 3. Swirling navy plasma inside the sphere
    canvas.save();
    canvas.clipPath(Path()..addOval(sphereRect));
    _drawBlobs(canvas, c, rr, t * 2 * math.pi, 0.45, 3);
    _drawBlobs(canvas, c, rr, -t * 4 * math.pi, 0.3, 5);
    canvas.restore();

    // 4. Specular highlight
    final Offset hc = c + Offset(-rr * 0.38, -rr * 0.42);
    canvas.drawCircle(
      hc,
      rr * 0.45,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0),
        ]).createShader(Rect.fromCircle(center: hc, radius: rr * 0.45)),
    );

    // 5. Rim glow (navy blue)
    canvas.drawCircle(
      c,
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = navyRim.withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // 6. Orbiting sparks
    for (int i = 0; i < 6; i++) {
      final double a = t * 2 * math.pi * (1 + i * 0.08) + i * math.pi / 3;
      final double d = rr * (1.22 + 0.08 * math.sin(t * 2 * math.pi * 3 + i));
      final Offset p = c + Offset(math.cos(a) * d, math.sin(a) * d * 0.9);
      canvas.drawCircle(
        p,
        1.8 + (i % 2),
        Paint()
          ..color = navySpark.withOpacity(0.5 + 0.4 * intensity),
      );
    }
  }

  void _drawBlobs(
    Canvas canvas,
    Offset c,
    double r,
    double angle,
    double spread,
    int count,
  ) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);

    for (int i = 0; i < count; i++) {
      final double a = i * 2 * math.pi / count;
      final Offset p = Offset(
        math.cos(a) * r * spread,
        math.sin(a) * r * spread,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p, width: r * 0.9, height: r * 0.45),
        Paint()
          ..color = (i.isEven ? navyBlue : const Color(0xFF2B4BA8))
              .withOpacity(0.35 + 0.2 * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => true;
}