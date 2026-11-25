import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Original vector kangaroo drawn with articulated parts, animated through a hop cycle.
class HoppingKangaroo extends StatefulWidget {
  final double height;
  const HoppingKangaroo({super.key, this.height = 260});
  @override
  State<HoppingKangaroo> createState() => _HoppingKangarooState();
}

class _HoppingKangarooState extends State<HoppingKangaroo> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, __) => CustomPaint(size: Size(widget.height * 1.45, widget.height), painter: KangarooPainter(c.value)),
      );
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _ease(double t) => t * t * (3 - 2 * t);
double _rad(double d) => d * math.pi / 180;

class KangarooPainter extends CustomPainter {
  final double t;
  KangarooPainter(this.t);

  static const body = Color(0xFFF2F2F2);
  static const line = Color(0xFF161616);

  // extension k (0 crouched, 1 stretched), height h (0..1), squat s (0..1), pitch (deg)
  (double, double, double, double) phase() {
    if (t < 0.22) { final u = _ease(t / 0.22); return (0, 0, u, 0); }
    if (t < 0.32) { final u = _ease((t - 0.22) / 0.10); return (u, 0, 1 - u, -6 * u); }
    if (t < 0.72) { final u = (t - 0.32) / 0.40; return (_lerp(1, .8, u), math.sin(math.pi * u), 0, _lerp(-12, 12, u)); }
    if (t < 0.82) { final u = _ease((t - 0.72) / 0.10); return (_lerp(.8, 0, u), 0, u, _lerp(12, 0, u)); }
    final u = _ease((t - 0.82) / 0.18); return (0, 0, 1 - u, 0);
  }

  void limb(Canvas cv, Offset a, Offset b, double ra, double rb, Paint p) {
    cv.drawCircle(a, ra, p);
    cv.drawCircle(b, rb, p);
    final d = b - a;
    final len = d.distance;
    if (len == 0) return;
    final n = Offset(-d.dy / len, d.dx / len);
    final path = Path()..moveTo(a.dx + n.dx * ra, a.dy + n.dy * ra)..lineTo(b.dx + n.dx * rb, b.dy + n.dy * rb)..lineTo(b.dx - n.dx * rb, b.dy - n.dy * rb)..lineTo(a.dx - n.dx * ra, a.dy - n.dy * ra)..close();
    cv.drawPath(path, p);
  }

  Offset pt(Offset o, double deg, double len) => Offset(o.dx + math.cos(_rad(deg)) * len, o.dy + math.sin(_rad(deg)) * len);

  @override
  void paint(Canvas cv, Size size) {
    final sc = size.height / 300;
    final (k, h, s, pitch) = phase();
    cv.scale(sc);
    final groundY = 285.0;
    // shadow
    final sh = Paint()..color = const Color(0x33FFFFFF);
    cv.drawOval(Rect.fromCenter(center: Offset(190, groundY + 8), width: _lerp(230, 120, h), height: _lerp(16, 8, h)), sh);

    final dy = -78 * h + 14 * s;
    cv.save();
    cv.translate(0, dy);
    cv.save();
    cv.translate(190, 170);
    cv.rotate(_rad(pitch));
    cv.translate(-190, -170);

    final p = Paint()..color = body..style = PaintingStyle.fill..isAntiAlias = true;
    final ln = Paint()..color = line..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;

    // tail (behind): chain of tapered segments, swings against the hop
    final tailBase = const Offset(150, 168);
    final tA = _lerp(165, 150, k) + pitch * -0.8 + math.sin(t * math.pi * 2) * 5;
    final t1 = pt(tailBase, tA, 62);
    final t2 = pt(t1, tA + _lerp(18, 6, k), 58);
    final t3 = pt(t2, tA + _lerp(32, 10, k), 48);
    limb(cv, tailBase, t1, 20, 14, p);
    limb(cv, t1, t2, 14, 8, p);
    limb(cv, t2, t3, 8, 2.5, p);

    // far hind leg slightly offset for depth
    final p2 = Paint()..color = const Color(0xFFBDBDBD);
    final hip = const Offset(178, 178);
    final a1 = _lerp(62, 112, k), a2 = _lerp(128, 152, k), a3 = _lerp(-4, 168, k);
    final hip2 = hip + const Offset(10, 4);
    final knee2 = pt(hip2, a1 - 6, 64);
    final ank2 = pt(knee2, a2 + 4, 70);
    final toe2 = pt(ank2, a3, 60);
    limb(cv, hip2, knee2, 28, 17, p2);
    limb(cv, knee2, ank2, 14, 7, p2);
    limb(cv, ank2, toe2, 7, 5, p2);

    // torso
    final torso = Path()
      ..moveTo(146, 176)
      ..cubicTo(136, 124, 190, 96, 246, 102)
      ..cubicTo(296, 108, 312, 156, 276, 196)
      ..cubicTo(248, 226, 172, 226, 146, 176)
      ..close();
    cv.drawPath(torso, p);
    // chest / abs detail
    cv.drawArc(Rect.fromLTWH(232, 128, 52, 44), _rad(20), _rad(130), false, ln);
    cv.drawLine(const Offset(250, 150), const Offset(262, 205), ln);
    cv.drawArc(Rect.fromLTWH(168, 118, 70, 60), _rad(190), _rad(80), false, ln);
    // thigh muscle line
    cv.drawArc(Rect.fromCenter(center: hip + const Offset(4, 18), width: 52, height: 62), _rad(100), _rad(110), false, ln);

    // hind leg: thigh, shin, foot
        final knee = pt(hip, a1, 66);
    final ank = pt(knee, a2, 72);
    final toe = pt(ank, a3, _lerp(62, 70, k));
    limb(cv, hip, knee, 34, 20, p); // big thigh
    limb(cv, knee, ank, 17, 8, p);
    limb(cv, ank, toe, 8, 6, p);
    // neck + head
    final neck = Path()
      ..moveTo(240, 112)
      ..cubicTo(244, 84, 262, 66, 284, 62)
      ..lineTo(300, 100)
      ..cubicTo(290, 120, 270, 132, 262, 138)
      ..close();
    cv.drawPath(neck, p);
    cv.save();
    cv.translate(288, 66);
    cv.rotate(_rad(-14 + pitch * .5));
    final head = Path()
      ..moveTo(-24, 6)
      ..cubicTo(-22, -20, 8, -24, 26, -10)
      ..lineTo(58, 2)
      ..cubicTo(64, 6, 62, 12, 54, 14)
      ..lineTo(26, 20)
      ..cubicTo(6, 28, -22, 24, -24, 6)
      ..close();
    cv.drawPath(head, p);
    // ears
    final ear = Path()..moveTo(-12, -14)..lineTo(-26, -58)..lineTo(6, -22)..close();
    cv.drawPath(ear, p);
    final ear2 = Path()..moveTo(-2, -18)..lineTo(-4, -60)..lineTo(16, -18)..close();
    cv.drawPath(ear2, Paint()..color = const Color(0xFFBDBDBD));
    cv.drawCircle(const Offset(22, 0), 3.4, Paint()..color = line);
    cv.drawLine(const Offset(40, 0), const Offset(60, 4), ln..strokeWidth = 2);
    cv.restore();

    // near arm (muscular): shoulder to elbow to fist
    final sh1 = const Offset(256, 140);
    final aa = _lerp(75, 130, k) + math.sin(t * math.pi * 2) * 6;
    final el = pt(sh1, aa, 40);
    final fi = pt(el, _lerp(20, 105, k), 38);
    limb(cv, sh1, el, 20, 13, p);
    limb(cv, el, fi, 13, 9, p);
    cv.drawCircle(fi, 10, p);
    cv.drawArc(Rect.fromCenter(center: sh1 + const Offset(8, 8), width: 34, height: 30), _rad(200), _rad(100), false, ln..strokeWidth = 3);
    cv.restore();
    cv.restore();
  }

  @override
  bool shouldRepaint(KangarooPainter o) => o.t != t;
}
