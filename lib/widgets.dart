import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'data.dart';
import 'l10n.dart';

const bgGreen = Color(0xFFEAF4DC);
const dark = Color(0xFF17301F);
const lime = Color(0xFFC6F135);
const card = Colors.white;
const muted = Color(0xFF5E7364);

class Heading extends StatelessWidget {
  final String text; final double size;
  const Heading(this.text, {super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned(left: 0, right: 0, bottom: 2, child: Container(height: size * .42, decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(8)))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: dark, height: 1.2))),
      ]);
}

class Pad extends StatelessWidget {
  final Widget child; final EdgeInsetsGeometry? margin; final VoidCallback? onTap; final Color? color;
  const Pad({super.key, required this.child, this.margin, this.onTap, this.color});
  @override
  Widget build(BuildContext context) => Container(
        margin: margin ?? const EdgeInsets.only(bottom: 12),
        child: Material(color: color ?? card, borderRadius: BorderRadius.circular(24), child: InkWell(borderRadius: BorderRadius.circular(24), onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: child))),
      );
}

class Pill extends StatelessWidget {
  final String text; final bool on; final VoidCallback? onTap;
  const Pill(this.text, {super.key, this.on = false, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(duration: const Duration(milliseconds: 150), margin: const EdgeInsetsDirectional.only(end: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(color: on ? dark : Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Text(text, style: TextStyle(color: on ? lime : dark, fontWeight: FontWeight.w700))),
      );
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
          Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: done ? lime : (on ? dark : Colors.white), border: Border.all(color: on ? dark : Colors.transparent)),
              child: done ? const Icon(Icons.check, size: 18, color: dark) : Text(bottom, style: TextStyle(fontWeight: FontWeight.w800, color: on ? lime : dark))),
          const SizedBox(height: 3),
          Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: dot ? dark : Colors.transparent)),
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
      decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(6),
      child: AspectRatio(aspectRatio: 1, child: Stack(fit: StackFit.expand, children: [
        for (final f in frames) Offstage(offstage: f != cur, child: SvgPicture.asset('assets/ex/${widget.ex.id}/$f.svg', fit: BoxFit.contain)),
      ])),
    );
    return widget.size != null ? box : AspectRatio(aspectRatio: 1, child: box);
  }
}

Future<bool> confirm(BuildContext c, String title, String body, String yes) async {
  final r = await showDialog<bool>(context: c, builder: (_) => AlertDialog(title: Text(title), content: Text(body), actions: [
    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancel'))),
    TextButton(onPressed: () => Navigator.pop(c, true), child: Text(yes)),
  ]));
  return r ?? false;
}
