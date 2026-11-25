import 'dart:convert';
import 'kangaroo.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'data.dart';
import 'l10n.dart';
import 'screens.dart';
import 'store.dart';
import 'widgets.dart';

const kVersion = '1.1';
const kCoachUrl = 'https://rlpfwpvdcvofcirmbkom.supabase.co/functions/v1/coach-ai';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  await Data.load();
  runApp(const KangarooApp());
}

class KangarooApp extends StatelessWidget {
  const KangarooApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: langPref,
        builder: (_, __, ___) => MaterialApp(
          title: 'Kangaroo Muscle',
          debugShowCheckedModeBanner: false,
          locale: Locale(lang),
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: bgGreen, colorScheme: ColorScheme.fromSeed(seedColor: lime, brightness: Brightness.dark, primary: lime, surface: bgGreen), pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: FadeSlideTransitions(), TargetPlatform.iOS: FadeSlideTransitions()})),
          builder: (c, w) => Directionality(textDirection: isAr ? TextDirection.rtl : TextDirection.ltr, child: w!),
          home: ValueListenableBuilder<int>(valueListenable: Store.tick, builder: (_, __, ___) => Store.onboarded ? const Shell() : const Onboarding()),
        ),
      );
}

// ---------------------------------------------------------------- Shell with pill nav
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  static const items = [(Icons.home_rounded, 'Home'), (Icons.explore_rounded, 'Explore'), (Icons.bar_chart_rounded, 'Activity'), (Icons.smart_toy_rounded, 'Coach'), (Icons.menu_rounded, 'More')];
  @override
  Widget build(BuildContext context) {
    final pages = [const HomeTab(), const ExploreTab(), const ActivityTab(), const CoachTab(), const MoreTab()];
    return Scaffold(
      backgroundColor: bgGreen,
      extendBody: true,
      body: SafeArea(bottom: false, child: Column(children: [
        ValueListenableBuilder<int>(valueListenable: Store.tick, builder: (_, __, ___) => Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Row(children: [Pressable(child: Avatar(size: 38, onTap: () => setState(() => i = 4))), const SizedBox(width: 10), const Text('Kangaroo Muscle', style: TextStyle(fontWeight: FontWeight.w900, color: muted, fontSize: 13))]))),
        Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 280), switchInCurve: Curves.easeOut, transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(a), child: c)), child: KeyedSubtree(key: ValueKey(i), child: pages[i]))),
      ])),
      bottomNavigationBar: SafeArea(child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(40), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 6))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          for (var k = 0; k < items.length; k++) Pressable(child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => i = k),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(duration: const Duration(milliseconds: 250), curve: Curves.easeOutBack, width: i == k ? 54 : 46, height: i == k ? 54 : 46,
                decoration: BoxDecoration(shape: BoxShape.circle, color: i == k ? lime : const Color(0xFFE2E2E2)),
                child: Icon(items[k].$1, size: 24, color: dark)),
              const SizedBox(height: 3),
              Text(tr(items[k].$2), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: dark)),
            ]))),
        ]),
      )),
    );
  }
}

// ---------------------------------------------------------------- Onboarding
class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int step = 0; // 0 = language only
  final name = TextEditingController();
  final h = TextEditingController(text: '170');
  final w = TextEditingController(text: '70');
  String gender = 'male';
  DateTime birth = DateTime(2000, 1, 1);
  String mode = 'home';

  Future<void> next() async {
    if (step < 7) { setState(() => step++); return; }
    await Store.setProfile(name: name.text.trim(), gender: gender, birth: birth, height: double.tryParse(h.text) ?? 170, weight: double.tryParse(w.text) ?? 70, mode: mode);
    await Store.finishOnboarding();
  }

  Widget field(TextEditingController c, String label, {bool num = false}) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextField(controller: c, keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.name, decoration: InputDecoration(labelText: label, filled: true, fillColor: card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none))));

  Widget langPage() => Column(children: [
        const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          HoppingKangaroo(height: 250),
          SizedBox(height: 18),
          Text('Kangaroo Muscle', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: ink)),
        ]))),
        for (final l in const [('ar', 'العربية'), ('en', 'English')])
          Padding(padding: const EdgeInsets.only(bottom: 12), child: SizedBox(width: double.infinity, child: Pressable(child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: l.$1 == 'ar' ? lime : card, foregroundColor: l.$1 == 'ar' ? dark : ink, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
            onPressed: () async { await Store.setLang(l.$1); setState(() => step = 1); },
            child: Text(l.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          )))),
        const SizedBox(height: 24),
      ]);

  @override
  Widget build(BuildContext context) {
    if (step == 0) return Scaffold(backgroundColor: bgGreen, body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: langPage())));
    Widget tile(String label, IconData ic, bool on, VoidCallback f) => Pad(color: on ? lime : card, onTap: f, child: Row(children: [Icon(ic, color: on ? dark : ink, size: 34), const SizedBox(width: 12), Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: on ? dark : ink))]));
    final pages = <int, Widget>{
      1: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Heading(tr('Your name'), size: 26), const SizedBox(height: 20), field(name, tr('Your name'))]),
      2: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Heading(tr('Gender'), size: 26), const SizedBox(height: 20),
        tile(tr('Male'), Icons.male, gender == 'male', () => setState(() => gender = 'male')), tile(tr('Female'), Icons.female, gender == 'female', () => setState(() => gender = 'female'))]),
      3: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Heading(tr('Birth date'), size: 26), const SizedBox(height: 20),
        Pad(onTap: () async { final d = await showDatePicker(context: context, initialDate: birth, firstDate: DateTime(1930), lastDate: DateTime.now()); if (d != null) setState(() => birth = d); }, child: Row(children: [const Icon(Icons.cake, color: lime), const SizedBox(width: 12), Text(dkey(birth), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink))]))]),
      4: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Heading(tr('Height (cm)'), size: 26), const SizedBox(height: 20), field(h, tr('Height (cm)'), num: true)]),
      5: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Heading(tr('Weight (kg)'), size: 26), const SizedBox(height: 20), field(w, tr('Weight (kg)'), num: true)]),
      6: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Heading(tr('Where do you train?'), size: 26), const SizedBox(height: 20),
        tile(tr('At home'), Icons.home_rounded, mode == 'home', () => setState(() => mode = 'home')), tile(tr('At the gym'), Icons.fitness_center, mode == 'gym', () => setState(() => mode = 'gym'))]),
      7: ValueListenableBuilder<int>(valueListenable: Store.tick, builder: (_, __, ___) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Heading(tr('Your photo'), size: 26), const SizedBox(height: 20),
        Center(child: Avatar(size: 130, onTap: pickPhoto)), const SizedBox(height: 16),
        Center(child: OutlinedButton.icon(onPressed: pickPhoto, icon: const Icon(Icons.photo_library), label: Text(tr('Choose photo')))),
        const SizedBox(height: 10),
        Text('${tr('Optional.')} ${tr('Your data stays on this phone.')}', style: const TextStyle(color: muted)),
      ])),
    };
    return Scaffold(
      backgroundColor: bgGreen,
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
        Row(children: [Image.asset('assets/brand/icon.png', width: 44, height: 44), const SizedBox(width: 10), const Text('Kangaroo Muscle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: ink))]),
        const SizedBox(height: 22),
        Expanded(child: SingleChildScrollView(child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: KeyedSubtree(key: ValueKey(step), child: pages[step]!)))),
        Row(children: [
          TextButton(onPressed: () => setState(() => step--), child: Text(tr('Back'))),
          const Spacer(),
          Pressable(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: lime, foregroundColor: dark, padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14)), onPressed: next, child: Text(step < 7 ? tr('Next') : tr('Finish'), style: const TextStyle(fontWeight: FontWeight.w900)))),
        ]),
      ]))),
    );
  }
}

// ---------------------------------------------------------------- Coach
class CoachTab extends StatefulWidget {
  const CoachTab({super.key});
  @override
  State<CoachTab> createState() => _CoachTabState();
}

class _CoachTabState extends State<CoachTab> {
  final c = TextEditingController();
  final sc = ScrollController();
  List<Map> msgs = Store.chat;
  bool busy = false;

  Future<void> send() async {
    final t = c.text.trim();
    if (t.isEmpty || busy) return;
    c.clear();
    setState(() { msgs.add({'role': 'user', 'content': t}); busy = true; });
    String ans;
    try {
      final r = await http.post(Uri.parse(kCoachUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
        'messages': msgs.length > 12 ? msgs.sublist(msgs.length - 12) : msgs,
        'lang': lang,
        'profile': {'name': Store.name, 'gender': Store.gender, 'age': Store.age, 'heightCm': Store.height, 'weightKg': Store.weight, 'mode': Store.mode},
      })).timeout(const Duration(seconds: 40));
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      ans = stripMd((j['answer'] ?? '').toString());
      if (r.statusCode != 200 || ans.isEmpty) ans = tr('The coach is not available right now. Try again later.');
    } catch (_) {
      ans = tr('The coach is not available right now. Try again later.');
    }
    if (!mounted) return;
    setState(() { msgs.add({'role': 'assistant', 'content': ans}); busy = false; });
    await Store.saveChat(msgs);
    await Future.delayed(const Duration(milliseconds: 100));
    if (sc.hasClients) sc.animateTo(sc.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 6), child: Align(alignment: AlignmentDirectional.centerStart, child: Heading(tr('Ask your coach'), size: 26))),
        Container(margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: lime.withValues(alpha: .18), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.info_outline, size: 18, color: lime), const SizedBox(width: 8), Expanded(child: Text(tr('Not medical advice. Check with a doctor before starting a new program.'), style: const TextStyle(fontSize: 12, color: ink)))])),
        Expanded(child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(18, 8, 18, 8), children: [
          _bubble(tr('Coach hello'), false),
          for (final m in msgs) _bubble(m['content'], m['role'] == 'user'),
          if (busy) _bubble(tr('Thinking...'), false),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 100), child: Row(children: [
          Expanded(child: TextField(controller: c, onSubmitted: (_) => send(), decoration: InputDecoration(hintText: tr('Type a message'), filled: true, fillColor: card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
          const SizedBox(width: 8),
          Pressable(child: IconButton.filled(style: IconButton.styleFrom(backgroundColor: lime, foregroundColor: dark), onPressed: send, icon: const Icon(Icons.send))),
        ])),
      ]);

  Widget _bubble(String t, bool me) => Align(
        alignment: me ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78), decoration: BoxDecoration(color: me ? lime : card, borderRadius: BorderRadius.circular(22)), child: SelectableText(t, style: TextStyle(color: me ? dark : ink, height: 1.4))),
      );
}

// ---------------------------------------------------------------- More
class MoreTab extends StatefulWidget {
  const MoreTab({super.key});
  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
  late final name = TextEditingController(text: Store.name);
  late final h = TextEditingController(text: Store.height == 0 ? '' : Store.height.toStringAsFixed(0));
  late final w = TextEditingController(text: Store.weight == 0 ? '' : Store.weight.toString());

  Widget field(TextEditingController c, String label, void Function(String) on, {bool num = false}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, onChanged: on, keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.name, decoration: InputDecoration(labelText: label, filled: true, fillColor: card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))));

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(valueListenable: Store.tick, builder: (_, __, ___) => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 110), children: [
        Heading(tr('More'), size: 26),
        const SizedBox(height: 14),
        Text(tr('Profile'), style: const TextStyle(fontWeight: FontWeight.w800, color: muted)),
        const SizedBox(height: 8),
        Center(child: Column(children: [Avatar(size: 96, onTap: pickPhoto), TextButton(onPressed: pickPhoto, child: Text(tr('Change photo'))), if (Store.photo != null) TextButton(onPressed: () => Store.setPhoto(null), child: Text(tr('Remove photo')))])),
        field(name, tr('Your name'), (v) => Store.setProfile(name: v.trim())),
        Row(children: [Pill(tr('Male'), on: Store.gender == 'male', onTap: () => Store.setProfile(gender: 'male')), Pill(tr('Female'), on: Store.gender == 'female', onTap: () => Store.setProfile(gender: 'female'))]),
        const SizedBox(height: 10),
        Pad(onTap: () async { final d = await showDatePicker(context: context, initialDate: Store.birth ?? DateTime(2000), firstDate: DateTime(1930), lastDate: DateTime.now()); if (d != null) Store.setProfile(birth: d); }, child: Row(children: [const Icon(Icons.cake, color: lime), const SizedBox(width: 12), Expanded(child: Text('${tr('Birth date')}: ${Store.birth == null ? '-' : dkey(Store.birth!)}')), Text('${Store.age}', style: const TextStyle(fontWeight: FontWeight.w900))])),
        field(h, tr('Height (cm)'), (v) { final x = double.tryParse(v); if (x != null) Store.setProfile(height: x); }, num: true),
        field(w, tr('Weight (kg)'), (v) { final x = double.tryParse(v); if (x != null) Store.setProfile(weight: x); }, num: true),
        const SizedBox(height: 6),
        Text(tr('Mode'), style: const TextStyle(fontWeight: FontWeight.w800, color: muted)),
        const SizedBox(height: 8),
        Row(children: [Pill(tr('At home'), on: Store.mode == 'home', onTap: () => Store.setProfile(mode: 'home')), Pill(tr('At the gym'), on: Store.mode == 'gym', onTap: () => Store.setProfile(mode: 'gym'))]),
        const SizedBox(height: 14),
        Text(tr('Language'), style: const TextStyle(fontWeight: FontWeight.w800, color: muted)),
        const SizedBox(height: 8),
        Row(children: [for (final l in [('ar', 'العربية'), ('en', 'English')]) Pill(l.$2, on: langPref.value == l.$1, onTap: () => Store.setLang(l.$1))]),
        const SizedBox(height: 18),
        Pad(onTap: () async { if (await confirm(context, tr('Delete all data?'), tr('This removes your profile, history and schedule from this phone.'), tr('Delete'))) { await Store.deleteAll(); } }, color: Colors.white, child: Row(children: [const Icon(Icons.delete_forever, color: Color(0xFFFF6B6B)), const SizedBox(width: 12), Text(tr('Delete my data'), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF6B6B)))])),
        Pad(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Image.asset('assets/brand/icon.png', width: 44, height: 44), const SizedBox(width: 10), const Text('Kangaroo Muscle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))]),
          const SizedBox(height: 8),
          Text('${tr('Version')} $kVersion', style: const TextStyle(color: muted)),
          Text(tr('No ads. No login. Works offline.'), style: const TextStyle(color: muted)),
          const SizedBox(height: 6),
          Text(tr('Not medical advice.'), style: const TextStyle(color: muted)),
        ])),
      ]));
}

class FadeSlideTransitions extends PageTransitionsBuilder {
  const FadeSlideTransitions();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> a, Animation<double> sa, Widget child) {
    final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
    return FadeTransition(opacity: curved, child: SlideTransition(position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(curved), child: child));
  }
}

String stripMd(String s) {
  var t = s.replaceAll(RegExp(r'\*\*|__|`|#{1,6} ?'), '');
  t = t.replaceAll(RegExp(r'^\s*[-*] ', multiLine: true), '• ');
  t = t.split('\n').where((l) => !RegExp(r'^\s*\|?[\s:|-]+\|?\s*$').hasMatch(l) || l.trim().isEmpty).map((l) => l.contains('|') ? l.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).join(' · ') : l).join('\n');
  return t.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}
