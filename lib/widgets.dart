import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'data.dart';
import 'l10n.dart';
import 'store.dart';
import 'package:image_picker/image_picker.dart';

const bgGreen = Color(0xFF161616); // app background, same as the logo
const dark = Color(0xFF161616); // text on light/lime fills
const ink = Color(0xFFF2F2F2); // main text
const panel = Color(0xFF2A2A2A); // raised panel
const lime = Color(0xFFC6F135);
const lav = Color(0xFFB9A7F5);
const card = Color(0xFF232323);
const muted = Color(0xFF9A9A9A);

class Heading extends StatelessWidget {
  final String text; final double size;
  const Heading(this.text, {super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned(left: 4, bottom: 0, child: Container(height: 4, width: size * 1.6, decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(8)))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: ink, height: 1.35))),
      ]);
}

class Pad extends StatelessWidget {
  final Widget child; final EdgeInsetsGeometry? margin; final VoidCallback? onTap; final Color? color;
  const Pad({super.key, required this.child, this.margin, this.onTap, this.color});
  @override
  Widget build(BuildContext context) => Container(
        margin: margin ?? const EdgeInsets.only(bottom: 12),
        child: onTap == null ? Material(color: color ?? card, borderRadius: BorderRadius.circular(28), child: Padding(padding: const EdgeInsets.all(16), child: child)) : Pressable(child: AnimatedContainer(duration: const Duration(milliseconds: 250), decoration: BoxDecoration(color: color ?? card, borderRadius: BorderRadius.circular(28)), child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(28), child: InkWell(borderRadius: BorderRadius.circular(28), onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: child))))),
      );
}

class Pill extends StatelessWidget {
  final String text; final bool on; final VoidCallback? onTap;
  const Pill(this.text, {super.key, this.on = false, this.onTap});
  @override
  Widget build(BuildContext context) => Pressable(child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(duration: const Duration(milliseconds: 220), curve: Curves.easeOut, margin: const EdgeInsetsDirectional.only(end: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(color: on ? lime : card, borderRadius: BorderRadius.circular(30)),
            child: Text(text, style: TextStyle(color: on ? dark : ink, fontWeight: FontWeight.w700))),
      ));
}

class DayChip extends StatelessWidget {
  final String top; final String bottom; final bool on; final bool done; final bool dot; final VoidCallback? onTap;
  const DayChip(this.top, this.bottom, {super.key, this.on = false, this.done = false, this.dot = false, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(top, style: const TextStyle(fontSize: 11, color: muted)),
          const SizedBox(height: 4),
          Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: done ? lime : (on ? ink : card), border: Border.all(color: Colors.transparent)),
              child: done ? const Icon(Icons.check, size: 18, color: dark) : Text(bottom, style: TextStyle(fontWeight: FontWeight.w800, color: on ? dark : ink))),
          const SizedBox(height: 3),
          Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: dot ? lime : Colors.transparent)),
        ]),
      );
}

/// Plays the three SVG frames in order [0,1,2,1] at the stated frame duration.
class ExAnim extends StatefulWidget {
  final Ex ex; final bool animate; final double? size;
  const ExAnim(this.ex, {super.key, this.animate = true, this.size});
  @override
  State<ExAnim> createState() => _ExAnimState();
}

class _ExAnimState extends State<ExAnim> {
  static const seq = [0, 1, 2, 1];
  int step = 0;
  Timer? t;
  @override
  void initState() {
    super.initState();
    if (widget.animate) t = Timer.periodic(Duration(milliseconds: widget.ex.dur), (_) { if (mounted) setState(() => step = (step + 1) % seq.length); });
  }
  @override
  void dispose() { t?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final cur = widget.animate ? seq[step] : 1;
    final frames = widget.animate ? [0, 1, 2] : [1];
    final box = Container(
      width: widget.size, height: widget.size,
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(6),
      child: AspectRatio(aspectRatio: 1, child: Stack(fit: StackFit.expand, children: [
        for (final f in frames) Offstage(offstage: f != cur, child: SvgPicture.asset('assets/ex/${widget.ex.id}/$f.svg', fit: BoxFit.contain)),
      ])),
    );
    return widget.size != null ? box : AspectRatio(aspectRatio: 1, child: box);
  }
}

Future<bool> confirm(BuildContext c, String title, String body, String yes) async {
  final r = await showDialog<bool>(context: c, builder: (_) => AlertDialog(backgroundColor: card, title: Text(title), content: Text(body), actions: [
    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancel'))),
    TextButton(onPressed: () => Navigator.pop(c, true), child: Text(yes)),
  ]));
  return r ?? false;
}

/// Animated ring (donut) progress chart.
class Ring extends StatelessWidget {
  final double value; final double size; final Widget? child; final Color color; final Color track;
  const Ring(this.value, {super.key, this.size = 96, this.child, this.color = lime, this.track = const Color(0x22FFFFFF)});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => SizedBox(width: size, height: size, child: CustomPaint(painter: _RingPainter(v, color, track), child: Center(child: child))),
      );
}

class _RingPainter extends CustomPainter {
  final double v; final Color c; final Color track;
  _RingPainter(this.v, this.c, this.track);
  @override
  void paint(Canvas cv, Size s) {
    final sw = s.width * .13;
    final r = Rect.fromLTWH(sw / 2, sw / 2, s.width - sw, s.height - sw);
    cv.drawArc(r, 0, math.pi * 2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = sw..color = track);
    cv.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, Paint()..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round..color = c);
  }
  @override
  bool shouldRepaint(_RingPainter o) => o.v != v;
}

/// Small round profile picture (own photo if set, else a person icon).
class Avatar extends StatelessWidget {
  final double size; final VoidCallback? onTap;
  const Avatar({super.key, this.size = 40, this.onTap});
  @override
  Widget build(BuildContext context) {
    final b = Store.photo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: panel, border: Border.all(color: lime, width: 2)),
        clipBehavior: Clip.antiAlias,
        child: b != null ? Image.memory(b, fit: BoxFit.cover, gaplessPlayback: true) : Icon(Icons.person, color: ink, size: size * .6),
      ),
    );
  }
}

Future<void> pickPhoto() async {
  try {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 80);
    if (f != null) await Store.setPhoto(await f.readAsBytes());
  } catch (_) {}
}

/// Press feedback: gentle scale-down and bounce back. Does not intercept taps.
class Pressable extends StatefulWidget {
  final Widget child;
  const Pressable({super.key, required this.child});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool down = false;
  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => setState(() => down = true),
        onPointerUp: (_) => setState(() => down = false),
        onPointerCancel: (_) => setState(() => down = false),
        child: AnimatedScale(scale: down ? .94 : 1, duration: Duration(milliseconds: down ? 90 : 260), curve: down ? Curves.easeOut : Curves.elasticOut, child: widget.child),
      );
}
