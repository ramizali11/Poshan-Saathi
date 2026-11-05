import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter that draws delicate organic leaves, vines, and floral petals
/// in sage green, deep emerald, and soft warm gold.
class BotanicalPainter extends CustomPainter {
  final double animationValue;

  BotanicalPainter({this.animationValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Top-Right Botanical Branch & Blossoms
    _drawTopRightCluster(canvas, size);

    // 2. Bottom-Left Botanical Branch & Leaves
    _drawBottomLeftCluster(canvas, size);

    // 3. Subtle floating petals & leaves in ambient background
    _drawAmbientPetals(canvas, size);
  }

  void _drawTopRightCluster(Canvas canvas, Size size) {
    final paintStem = Paint()
      ..color = const Color(0xFF176B3A).withOpacity(0.18)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pathStem = Path();
    pathStem.moveTo(size.width + 10, -10);
    pathStem.quadraticBezierTo(
      size.width - 60,
      40,
      size.width - 90,
      110,
    );
    pathStem.quadraticBezierTo(
      size.width - 110,
      160,
      size.width - 70,
      210,
    );
    canvas.drawPath(pathStem, paintStem);

    // Leaves along the stem
    _drawLeaf(canvas, Offset(size.width - 45, 30), -0.6, 26, const Color(0xFF289659).withOpacity(0.22));
    _drawLeaf(canvas, Offset(size.width - 75, 75), -1.1, 32, const Color(0xFF176B3A).withOpacity(0.20));
    _drawLeaf(canvas, Offset(size.width - 88, 125), -0.4, 28, const Color(0xFF4CAF50).withOpacity(0.24));
    _drawLeaf(canvas, Offset(size.width - 95, 170), -1.3, 24, const Color(0xFF1B5E20).withOpacity(0.18));
    _drawLeaf(canvas, Offset(size.width - 65, 205), -0.7, 22, const Color(0xFF2E7D32).withOpacity(0.20));

    // Delicate flowers/blossoms
    _drawFlower(canvas, Offset(size.width - 35, 60), 12, const Color(0xFFF59E0B).withOpacity(0.35), const Color(0xFFFDE68A).withOpacity(0.5));
    _drawFlower(canvas, Offset(size.width - 70, 140), 15, const Color(0xFFEC4899).withOpacity(0.28), const Color(0xFFFBCFE8).withOpacity(0.45));
    _drawFlower(canvas, Offset(size.width - 110, 85), 10, const Color(0xFF10B981).withOpacity(0.30), const Color(0xFFA7F3D0).withOpacity(0.45));
  }

  void _drawBottomLeftCluster(Canvas canvas, Size size) {
    final paintStem = Paint()
      ..color = const Color(0xFF176B3A).withOpacity(0.15)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pathStem = Path();
    pathStem.moveTo(-10, size.height + 10);
    pathStem.quadraticBezierTo(
      50,
      size.height - 60,
      90,
      size.height - 120,
    );
    pathStem.quadraticBezierTo(
      115,
      size.height - 180,
      75,
      size.height - 230,
    );
    canvas.drawPath(pathStem, paintStem);

    // Leaves
    _drawLeaf(canvas, Offset(35, size.height - 45), 2.4, 28, const Color(0xFF176B3A).withOpacity(0.18));
    _drawLeaf(canvas, Offset(70, size.height - 95), 1.9, 34, const Color(0xFF289659).withOpacity(0.22));
    _drawLeaf(canvas, Offset(92, size.height - 145), 2.5, 26, const Color(0xFF4CAF50).withOpacity(0.20));
    _drawLeaf(canvas, Offset(98, size.height - 195), 1.7, 24, const Color(0xFF1B5E20).withOpacity(0.18));
    _drawLeaf(canvas, Offset(70, size.height - 225), 2.2, 20, const Color(0xFF2E7D32).withOpacity(0.18));

    // Flowers
    _drawFlower(canvas, Offset(50, size.height - 80), 13, const Color(0xFFF59E0B).withOpacity(0.32), const Color(0xFFFDE68A).withOpacity(0.45));
    _drawFlower(canvas, Offset(105, size.height - 165), 11, const Color(0xFFEC4899).withOpacity(0.25), const Color(0xFFFBCFE8).withOpacity(0.40));
  }

  void _drawAmbientPetals(Canvas canvas, Size size) {
    // Floating gentle organic leaf/petal accents scattered across screen
    _drawPetal(canvas, Offset(size.width * 0.15, size.height * 0.22), 0.8, 10, const Color(0xFF10B981).withOpacity(0.12));
    _drawPetal(canvas, Offset(size.width * 0.85, size.height * 0.40), -1.2, 12, const Color(0xFFF59E0B).withOpacity(0.14));
    _drawPetal(canvas, Offset(size.width * 0.10, size.height * 0.58), 1.5, 11, const Color(0xFF289659).withOpacity(0.12));
    _drawPetal(canvas, Offset(size.width * 0.88, size.height * 0.72), -0.7, 13, const Color(0xFFEC4899).withOpacity(0.12));
    _drawPetal(canvas, Offset(size.width * 0.35, size.height * 0.90), 0.4, 9, const Color(0xFF4CAF50).withOpacity(0.10));
  }

  void _drawLeaf(Canvas canvas, Offset origin, double angle, double length, Color color) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(length * 0.4, -length * 0.35, length, 0);
    path.quadraticBezierTo(length * 0.4, length * 0.35, 0, 0);
    canvas.drawPath(path, paint);

    // Vein in the leaf
    final veinPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(length * 0.85, 0), veinPaint);

    canvas.restore();
  }

  void _drawFlower(Canvas canvas, Offset center, double radius, Color petalColor, Color centerColor) {
    const int numPetals = 5;
    final petalPaint = Paint()
      ..color = petalColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < numPetals; i++) {
      final double theta = (i * 2 * math.pi / numPetals);
      final double petalX = center.dx + math.cos(theta) * radius * 0.65;
      final double petalY = center.dy + math.sin(theta) * radius * 0.65;
      canvas.drawCircle(Offset(petalX, petalY), radius * 0.55, petalPaint);
    }

    // Flower Center
    final centerPaint = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.4, centerPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFD97706).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.18, dotPaint);
  }

  void _drawPetal(Canvas canvas, Offset center, double angle, double radius, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, -radius);
    path.quadraticBezierTo(radius * 0.6, 0, 0, radius);
    path.quadraticBezierTo(-radius * 0.6, 0, 0, -radius);
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BotanicalPainter oldDelegate) => false;
}

/// A wrapper widget that decorates any screen with soft floral & botanical elements
class BotanicalScreenWrapper extends StatelessWidget {
  final Widget child;
  final bool showHeaderFlowers;

  const BotanicalScreenWrapper({
    super.key,
    required this.child,
    this.showHeaderFlowers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9F6),
        gradient: LinearGradient(
          colors: [
            Color(0xFFFCFDFB),
            Color(0xFFF5F9F4),
            Color(0xFFEDF6EB),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Botanical Painter (Flowers, vines, and leaves)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BotanicalPainter(),
              ),
            ),
          ),

          // Main Screen Child
          child,
        ],
      ),
    );
  }
}

/// A decorative botanical header with laurel leaves and blossoms
class BotanicalLogoBadge extends StatelessWidget {
  final double size;

  const BotanicalLogoBadge({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 24,
      height: size + 24,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft ambient floral glow
          Container(
            width: size + 16,
            height: size + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE7F3E2).withOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF176B3A).withOpacity(0.18),
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Outer Floral Laurel Ring (Icons / Emojis / Decorative leaves)
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌿', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 3),
                  Text('🌸', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 3),
                  Text('🌿', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),

          // Main Center Circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF176B3A), Color(0xFF289659)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF176B3A).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

