import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'data.dart';
import 'l10n.dart';
import 'screens.dart';
import 'store.dart';
import 'widgets.dart';

const kVersion = '1.0';
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
          theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: bgGreen, colorScheme: ColorScheme.fromSeed(seedColor: lime, primary: dark, surface: bgGreen), fontFamily: null),
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
      body: SafeArea(bottom: false, child: IndexedStack(index: i, children: pages)),
      bottomNavigationBar: SafeArea(child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 12), padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(40), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, 4))]),
        child: Row(children: [
          for (var k = 0; k < items.length; k++) Expanded(child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => i = k),
            child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(color: i == k ? lime : Colors.transparent, borderRadius: BorderRadius.circular(30)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(items[k].$1, size: 22, color: i == k ? dark : Colors.white70), Text(tr(items[k].$2), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: i == k ? dark : Colors.white70))])),
          )),
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
  int step = 0;
  final name = TextEditingController();
  final h = TextEditingController(text: '170');
  final w = TextEditingController(text: '70');
  String gender = 'male';
  DateTime birth = DateTime(2000, 1, 1);
  String mode = 'home';

  Future<void> next() async {
    if (step < 3) { setState(() => step++); return; }
    await Store.setProfile(name: name.text.trim(), gender: gender, birth: birth, height: double.tryParse(h.text) ?? 170, weight: double.tryParse(w.text) ?? 70, mode: mode);
    await Store.finishOnboarding();
  }

  Widget field(TextEditingController c, String label, {bool num = false}) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextField(controller: c, keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.name, decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))));

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Heading(tr('Choose your language'), size: 24), const SizedBox(height: 14),
        Wrap(children: [for (final l in [('auto', tr('Auto')), ('ar', 'العربية'), ('en', 'English')]) Pill(l.$2, on: langPref.value == l.$1, onTap: () async { await Store.setLang(l.$1); setState(() {}); })]),
        const SizedBox(height: 24),
        field(name, tr('Your name')),
        Text(tr('Gender'), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
        Row(children: [Pill(tr('Male'), on: gender == 'male', onTap: () => setState(() => gender = 'male')), Pill(tr('Female'), on: gender == 'female', onTap: () => setState(() => gender = 'female'))]),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Heading(tr('Birth date'), size: 24), const SizedBox(height: 14),
        Pad(onTap: () async { final d = await showDatePicker(context: context, initialDate: birth, firstDate: DateTime(1930), lastDate: DateTime.now()); if (d != null) setState(() => birth = d); }, child: Row(children: [const Icon(Icons.cake, color: dark), const SizedBox(width: 12), Text(dkey(birth), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))])),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Heading('${tr('Height (cm)')} / ${tr('Weight (kg)')}', size: 22), const SizedBox(height: 14),
        field(h, tr('Height (cm)'), num: true), field(w, tr('Weight (kg)'), num: true),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Heading(tr('Where do you train?'), size: 24), const SizedBox(height: 14),
        Pad(color: mode == 'home' ? lime : Colors.white, onTap: () => setState(() => mode = 'home'), child: Row(children: [const Icon(Icons.home_rounded, color: dark, size: 34), const SizedBox(width: 12), Text(tr('At home'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))])),
        Pad(color: mode == 'gym' ? lime : Colors.white, onTap: () => setState(() => mode = 'gym'), child: Row(children: [const Icon(Icons.fitness_center, color: dark, size: 34), const SizedBox(width: 12), Text(tr('At the gym'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))])),
        const SizedBox(height: 10),
        Text(tr('Your data stays on this phone.'), style: const TextStyle(color: muted)),
      ]),
    ];
    return Scaffold(
      backgroundColor: bgGreen,
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
        Row(children: [Image.asset('assets/brand/icon.png', width: 44, height: 44), const SizedBox(width: 10), const Text('Kangaroo Muscle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: dark))]),
        const SizedBox(height: 22),
        Expanded(child: SingleChildScrollView(child: pages[step])),
        Row(children: [
          if (step > 0) TextButton(onPressed: () => setState(() => step--), child: Text(tr('Back'))),
          const Spacer(),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: dark, foregroundColor: lime, padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14)), onPressed: next, child: Text(step < 3 ? tr('Next') : tr('Finish'), style: const TextStyle(fontWeight: FontWeight.w900))),
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
      ans = (j['answer'] ?? '').toString();
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
        Container(margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: lime.withOpacity(.5), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.info_outline, size: 18, color: dark), const SizedBox(width: 8), Expanded(child: Text(tr('Not medical advice. Check with a doctor before starting a new program.'), style: const TextStyle(fontSize: 12, color: dark)))])),
        Expanded(child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(18, 8, 18, 8), children: [
          _bubble(tr('Coach hello'), false),
          for (final m in msgs) _bubble(m['content'], m['role'] == 'user'),
          if (busy) _bubble(tr('Thinking...'), false),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 100), child: Row(children: [
          Expanded(child: TextField(controller: c, onSubmitted: (_) => send(), decoration: InputDecoration(hintText: tr('Type a message'), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
          const SizedBox(width: 8),
          IconButton.filled(style: IconButton.styleFrom(backgroundColor: dark, foregroundColor: lime), onPressed: send, icon: const Icon(Icons.send)),
        ])),
      ]);

  Widget _bubble(String t, bool me) => Align(
        alignment: me ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78), decoration: BoxDecoration(color: me ? dark : Colors.white, borderRadius: BorderRadius.circular(20)), child: SelectableText(t, style: TextStyle(color: me ? Colors.white : dark, height: 1.4))),
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

  Widget field(TextEditingController c, String label, void Function(String) on, {bool num = false}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, onChanged: on, keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.name, decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))));

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(valueListenable: Store.tick, builder: (_, __, ___) => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 110), children: [
        Heading(tr('More'), size: 26),
        const SizedBox(height: 14),
        Text(tr('Profile'), style: const TextStyle(fontWeight: FontWeight.w800, color: muted)),
        const SizedBox(height: 8),
        field(name, tr('Your name'), (v) => Store.setProfile(name: v.trim())),
        Row(children: [Pill(tr('Male'), on: Store.gender == 'male', onTap: () => Store.setProfile(gender: 'male')), Pill(tr('Female'), on: Store.gender == 'female', onTap: () => Store.setProfile(gender: 'female'))]),
        const SizedBox(height: 10),
        Pad(onTap: () async { final d = await showDatePicker(context: context, initialDate: Store.birth ?? DateTime(2000), firstDate: DateTime(1930), lastDate: DateTime.now()); if (d != null) Store.setProfile(birth: d); }, child: Row(children: [const Icon(Icons.cake, color: dark), const SizedBox(width: 12), Expanded(child: Text('${tr('Birth date')}: ${Store.birth == null ? '-' : dkey(Store.birth!)}')), Text('${Store.age}', style: const TextStyle(fontWeight: FontWeight.w900))])),
        field(h, tr('Height (cm)'), (v) { final x = double.tryParse(v); if (x != null) Store.setProfile(height: x); }, num: true),
        field(w, tr('Weight (kg)'), (v) { final x = double.tryParse(v); if (x != null) Store.setProfile(weight: x); }, num: true),
        const SizedBox(height: 6),
        Text(tr('Mode'), style: const TextStyle(fontWeight: FontWeight.w800, color: muted)),
        const SizedBox(height: 8),
        Row(children: [Pill(tr('At home'), on: Store.mode == 'home', onTap: () => Store.setProfile(mode: 'home')), Pill(tr('At the gym'), on: Store.mode == 'gym', onTap: () => Store.setProfile(mode: 'gym'))]),
        const SizedBox(height: 14),
        Text(tr('Language'), style: const TextStyle(fontWeight: FontWeight.w800, color: muted)),
        const SizedBox(height: 8),
        Row(children: [for (final l in [('auto', tr('Auto')), ('ar', 'العربية'), ('en', 'English')]) Pill(l.$2, on: langPref.value == l.$1, onTap: () => Store.setLang(l.$1))]),
        const SizedBox(height: 18),
        Pad(onTap: () async { if (await confirm(context, tr('Delete all data?'), tr('This removes your profile, history and schedule from this phone.'), tr('Delete'))) { await Store.deleteAll(); } }, color: Colors.white, child: Row(children: [const Icon(Icons.delete_forever, color: Colors.red), const SizedBox(width: 12), Text(tr('Delete my data'), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.red))])),
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
