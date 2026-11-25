import 'dart:async';
import 'package:flutter/material.dart';
import 'data.dart';
import 'l10n.dart';
import 'store.dart';
import 'widgets.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
Template tpl(String id) => templates.firstWhere((t) => t.id == id);
int weekSeed(DateTime d) => d.difference(DateTime(2026, 1, 5)).inDays ~/ 7;
List<Entry> entriesFor(Template t, DateTime d) => Data.build(t, Store.mode, weekSeed(d));
String planFor(DateTime d) => programWeek[d.weekday] ?? '';
DateTime mondayOf(DateTime d) => DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

Future<void> startWorkout(BuildContext c, Template t, DateTime d, {bool program = false}) async {
  final e = entriesFor(t, d);
  if (e.isEmpty) return;
  await Navigator.push(c, MaterialPageRoute(builder: (_) => Player(t, e, program)));
}

// ---------------------------------------------------------------- Home
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(valueListenable: Store.tick, builder: (_, __, ___) {
        final now = DateTime.now();
        final id = planFor(now);
        final done = Store.sessions;
        final doneDates = {for (final s in done) s.date};
        final mon = mondayOf(now);
        final cycle = now.difference(Store.start).inDays ~/ 28;
        final cycleStart = Store.start.add(Duration(days: cycle * 28));
        final progDone = done.where((s) => s.tpl.isNotEmpty && !dparse(s.date).isBefore(cycleStart) && dparse(s.date).isBefore(cycleStart.add(const Duration(days: 28)))).length;
        final prog = (progDone / programTotal).clamp(0.0, 1.0);
        final e = id.isEmpty ? <Entry>[] : entriesFor(tpl(id), now);
        return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 110), children: [
          Row(children: [
            Expanded(child: Text('${tr('Hello')}${Store.name.isEmpty ? '' : ', ${Store.name}'}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark))),
            IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulePage())), icon: const Icon(Icons.calendar_month, color: dark)),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < 7; i++) () {
              final d = mon.add(Duration(days: i));
              return DayChip(tr(_days[i]), '${d.day}', on: dkey(d) == dkey(now), done: doneDates.contains(dkey(d)), dot: planFor(d).isNotEmpty);
            }(),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Pill(tr('At home'), on: Store.mode == 'home', onTap: () => Store.setProfile(mode: 'home'))),
            Expanded(child: Pill(tr('At the gym'), on: Store.mode == 'gym', onTap: () => Store.setProfile(mode: 'gym'))),
          ]),
          const SizedBox(height: 8),
          Pad(color: dark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text(tr('Program progress'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)), const Spacer(), Text('$progDone/$programTotal', style: const TextStyle(color: lime, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: prog, minHeight: 12, color: lime, backgroundColor: Colors.white24)),
          ])),
          const SizedBox(height: 4),
          Heading(tr("Today's workout")),
          const SizedBox(height: 10),
          if (id.isEmpty)
            Pad(child: Row(children: [const Icon(Icons.self_improvement, color: dark, size: 34), const SizedBox(width: 12), Expanded(child: Text(tr('Rest day'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))]))
          else
            Pad(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(tpl(id).title), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dark)),
              Text('${e.length} ${tr('exercises')} · ${tpl(id).mins} ${tr('min')}', style: const TextStyle(color: muted)),
              const SizedBox(height: 12),
              SizedBox(height: 86, child: ListView(scrollDirection: Axis.horizontal, children: [for (final x in e) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ExAnim(Data.byId[x.id]!, animate: false, size: 86))])),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: lime, foregroundColor: dark, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), onPressed: () => startWorkout(context, tpl(id), now, program: true), child: Text(tr('Start workout'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)))),
            ])),
          const SizedBox(height: 6),
          Heading(tr('Quick workouts')),
          const SizedBox(height: 10),
          SizedBox(height: 120, child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final t in templates.where((t) => t.id != id)) SizedBox(width: 160, child: Pad(margin: const EdgeInsetsDirectional.only(end: 10), onTap: () => startWorkout(context, t, now), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(tr(t.title), maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dark)),
              Row(children: [const Icon(Icons.play_circle_fill, color: dark), const SizedBox(width: 6), Text('${t.mins} ${tr('min')}', style: const TextStyle(color: muted))]),
            ]))),
          ])),
        ]);
      });
}

// ---------------------------------------------------------------- Explore
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});
  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  String col = 'strength';
  String q = '';
  String bp = '';
  static const cols = ['strength', 'hiit', 'mobility', 'yoga', 'running'];
  static const cl = {'strength': 'Strength', 'hiit': 'HIIT', 'mobility': 'Mobility', 'yoga': 'Yoga', 'running': 'Running'};
  static const parts = ['chest', 'back', 'shoulders', 'upper arms', 'upper legs', 'lower legs', 'waist', 'cardio'];
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(valueListenable: Store.tick, builder: (_, __, ___) {
        final pool = Data.forMode(Store.mode);
        var list = pool.where((e) => (bp.isEmpty || e.bp == bp) && (q.isEmpty || e.name.toLowerCase().contains(q.toLowerCase()))).toList();
        final ts = templates.where((t) => t.col == col).toList();
        return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 110), children: [
          Heading(tr('Explore'), size: 26),
          const SizedBox(height: 12),
          Text(tr('Collections'), style: const TextStyle(fontWeight: FontWeight.w800, color: muted)),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final c in cols) Pill(tr(cl[c]!), on: col == c, onTap: () => setState(() => col = c))])),
          const SizedBox(height: 8),
          for (final t in ts) Pad(onTap: () => startWorkout(context, t, DateTime.now()), child: Row(children: [
            Container(width: 46, height: 46, decoration: const BoxDecoration(color: lime, shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: dark)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(t.title), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text('${entriesFor(t, DateTime.now()).length} ${tr('exercises')} · ${t.mins} ${tr('min')}', style: const TextStyle(color: muted))])),
          ])),
          if (pool.where((e) => e.cols.contains(col)).isEmpty) const SizedBox.shrink(),
          const SizedBox(height: 8),
          Heading(tr('Exercise library')),
          const SizedBox(height: 10),
          TextField(onChanged: (v) => setState(() => q = v), decoration: InputDecoration(hintText: tr('Search exercises'), prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none))),
          const SizedBox(height: 10),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [Pill(tr('All'), on: bp.isEmpty, onTap: () => setState(() => bp = '')), for (final p in parts) Pill(tl(p), on: bp == p, onTap: () => setState(() => bp = p))])),
          const SizedBox(height: 10),
          for (final e in list.take(80)) Pad(margin: const EdgeInsets.only(bottom: 8), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExDetail(e))), child: Row(children: [
            ExAnim(e, animate: false, size: 64),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.cap, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${tl(e.bp)} · ${tl(e.eq)}', style: const TextStyle(color: muted, fontSize: 12))])),
          ])),
          if (list.length > 80) Center(child: Padding(padding: const EdgeInsets.all(8), child: Text('+${list.length - 80}', style: const TextStyle(color: muted)))),
        ]);
      });
}

class ExDetail extends StatelessWidget {
  final Ex e;
  const ExDetail(this.e, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bgGreen,
        appBar: AppBar(backgroundColor: bgGreen, elevation: 0, foregroundColor: dark, title: Text(e.cap, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          ExAnim(e),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [Pill(tl(e.bp), on: true), Pill(tl(e.eq)), Pill(tl(e.target))]),
          const SizedBox(height: 14),
          if (e.sm.isNotEmpty) Text('${tr('Also works')}: ${e.sm.map(tl).join(', ')}', style: const TextStyle(color: muted)),
          const SizedBox(height: 10),
          Heading(tr('How to')),
          if (isAr) Padding(padding: const EdgeInsets.only(top: 6), child: Text(tr('Instructions are in English for now.'), style: const TextStyle(color: muted, fontSize: 12))),
          const SizedBox(height: 10),
          for (var i = 0; i < e.ins.length; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 13, backgroundColor: lime, child: Text('${i + 1}', style: const TextStyle(color: dark, fontWeight: FontWeight.w900, fontSize: 12))),
            const SizedBox(width: 10),
            Expanded(child: Directionality(textDirection: TextDirection.ltr, child: Text(e.ins[i], style: const TextStyle(height: 1.4)))),
          ])),
        ]),
      );
}

// ---------------------------------------------------------------- Activity
class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(valueListenable: Store.tick, builder: (_, __, ___) {
        final now = DateTime.now();
        final all = Store.sessions;
        final month = all.where((s) { final d = dparse(s.date); return d.year == now.year && d.month == now.month; }).toList();
        final today = all.where((s) => s.date == dkey(now)).toList();
        final mon = mondayOf(now);
        final sched = Store.scheds;
        int sum(int Function(Session) f) => all.fold(0, (a, s) => a + f(s));
        return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 110), children: [
          Row(children: [Expanded(child: Heading(tr('Activity'), size: 26)), IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulePage())), icon: const Icon(Icons.calendar_month, color: dark))]),
          const SizedBox(height: 10),
          Pad(color: dark, child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('Days active this month'), style: const TextStyle(color: Colors.white70)), const SizedBox(height: 6), Text('${month.map((s) => s.date).toSet().length}', style: const TextStyle(color: lime, fontSize: 40, fontWeight: FontWeight.w900))])),
            const Icon(Icons.local_fire_department, color: lime, size: 48),
          ])),
          Heading(tr("Today's sessions")),
          const SizedBox(height: 8),
          if (today.isEmpty) Pad(child: Text(tr('No sessions yet'), style: const TextStyle(color: muted))),
          for (final s in today) Pad(margin: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.check_circle, color: dark), const SizedBox(width: 10), Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800))), Text('${s.mins} ${tr('min')}', style: const TextStyle(color: muted))])),
          const SizedBox(height: 8),
          Heading(tr('Weekly adherence')),
          const SizedBox(height: 8),
          Pad(child: Table(children: [
            TableRow(children: [const SizedBox(), for (var i = 0; i < 7; i++) Center(child: Text(tr(_days[i]), style: const TextStyle(fontSize: 11, color: muted)))]),
            TableRow(children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(tr('Planned'), style: const TextStyle(fontSize: 12))),
              for (var i = 0; i < 7; i++) () { final d = mon.add(Duration(days: i)); final p = planFor(d).isNotEmpty || sched.any((s) => s.date == dkey(d)); return Icon(p ? Icons.circle : Icons.circle_outlined, size: 14, color: p ? dark : Colors.black26); }(),
            ]),
            TableRow(children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(tr('Done'), style: const TextStyle(fontSize: 12))),
              for (var i = 0; i < 7; i++) () { final d = mon.add(Duration(days: i)); final dn = all.any((s) => s.date == dkey(d)); return Icon(dn ? Icons.check_circle : Icons.remove, size: 18, color: dn ? const Color(0xFF6BA000) : Colors.black26); }(),
            ]),
          ])),
          Heading(tr('Totals')),
          const SizedBox(height: 8),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.9, mainAxisSpacing: 10, crossAxisSpacing: 10, children: [
            for (final t in [(tr('Sessions'), all.length), (tr('Minutes'), sum((s) => s.mins)), (tr('Sets'), sum((s) => s.sets)), (tr('Reps'), sum((s) => s.reps))])
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text('${t.$2}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark)), Text(t.$1, style: const TextStyle(color: muted))])),
          ]),
        ]);
      });
}

// ---------------------------------------------------------------- Schedule
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime sel = DateTime.now();
  static const _mAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  static const _mEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  Future<void> add() async {
    String t = templates.first.id;
    TimeOfDay? time;
    final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, set) => AlertDialog(
      title: Text(tr('Add schedule')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButton<String>(isExpanded: true, value: t, items: [for (final x in templates) DropdownMenuItem(value: x.id, child: Text(tr(x.title)))], onChanged: (v) => set(() => t = v!)),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () async { final r = await showTimePicker(context: c, initialTime: const TimeOfDay(hour: 18, minute: 0)); if (r != null) set(() => time = r); }, icon: const Icon(Icons.access_time), label: Text(time == null ? tr('Time') : time!.format(c))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancel'))), TextButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Save')))],
    )));
    if (ok == true) {
      final ts = time == null ? '' : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';
      await Store.addSched(Sched(dkey(sel), t, ts));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday - 1;
    final n = DateTime(month.year, month.month + 1, 0).day;
    final sessions = Store.sessions;
    final scheds = Store.scheds;
    final selScheds = scheds.where((s) => s.date == dkey(sel)).toList();
    final selDone = sessions.where((s) => s.date == dkey(sel)).toList();
    final week = mondayOf(DateTime.now());
    return Scaffold(
      backgroundColor: bgGreen,
      appBar: AppBar(backgroundColor: bgGreen, elevation: 0, foregroundColor: dark, title: Text(tr('Schedule'), style: const TextStyle(fontWeight: FontWeight.w900))),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: lime, foregroundColor: dark, onPressed: add, icon: const Icon(Icons.add), label: Text(tr('Add schedule'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 100), children: [
        Row(children: [
          IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
          Expanded(child: Center(child: Text('${isAr ? _mAr[month.month - 1] : _mEn[month.month - 1]} ${month.year}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)))),
          IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right)),
        ]),
        Row(children: [for (final d in _days) Expanded(child: Center(child: Text(tr(d), style: const TextStyle(fontSize: 11, color: muted))))]),
        const SizedBox(height: 6),
        GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: .78, children: [
          for (var i = 0; i < lead; i++) const SizedBox(),
          for (var d = 1; d <= n; d++) () {
            final dt = DateTime(month.year, month.month, d);
            final k = dkey(dt);
            return Center(child: DayChip('', '$d', on: k == dkey(sel), done: sessions.any((s) => s.date == k), dot: scheds.any((s) => s.date == k) || planFor(dt).isNotEmpty, onTap: () => setState(() => sel = dt)));
          }(),
        ]),
        const SizedBox(height: 8),
        Heading(dkey(sel)),
        const SizedBox(height: 8),
        if (planFor(sel).isNotEmpty) Pad(margin: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.flag, color: dark), const SizedBox(width: 10), Expanded(child: Text('${tr('Program')}: ${tr(tpl(planFor(sel)).title)}', style: const TextStyle(fontWeight: FontWeight.w800)))])),
        for (final s in selScheds) Pad(margin: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.event, color: dark), const SizedBox(width: 10), Expanded(child: Text('${tr(tpl(s.tpl).title)}${s.time.isEmpty ? '' : ' · ${s.time}'}', style: const TextStyle(fontWeight: FontWeight.w800))), IconButton(onPressed: () async { await Store.removeSched(s); setState(() {}); }, icon: const Icon(Icons.delete_outline))])),
        for (final s in selDone) Pad(margin: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.check_circle, color: Color(0xFF6BA000)), const SizedBox(width: 10), Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800))), Text(tr('Done'), style: const TextStyle(color: muted))])),
        if (planFor(sel).isEmpty && selScheds.isEmpty && selDone.isEmpty) Pad(child: Text(tr('Nothing scheduled'), style: const TextStyle(color: muted))),
        const SizedBox(height: 8),
        Heading(tr('This week')),
        const SizedBox(height: 8),
        for (var i = 0; i < 7; i++) () {
          final d = week.add(Duration(days: i)); final k = dkey(d);
          final names = [if (planFor(d).isNotEmpty) tr(tpl(planFor(d)).title), for (final s in scheds.where((s) => s.date == k)) tr(tpl(s.tpl).title)];
          return Pad(margin: const EdgeInsets.only(bottom: 6), child: Row(children: [SizedBox(width: 56, child: Text('${tr(_days[i])} ${d.day}', style: const TextStyle(fontWeight: FontWeight.w800))), Expanded(child: Text(names.isEmpty ? tr('Rest day') : names.join(' + '), style: TextStyle(color: names.isEmpty ? muted : dark))), if (sessions.any((s) => s.date == k)) const Icon(Icons.check_circle, color: Color(0xFF6BA000))]));
        }(),
      ]),
    );
  }
}

// ---------------------------------------------------------------- Player
class Player extends StatefulWidget {
  final Template t; final List<Entry> entries; final bool program;
  const Player(this.t, this.entries, this.program, {super.key});
  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  int idx = 0, set = 1, rest = 0, tleft = 0;
  bool resting = false, timing = false, finished = false;
  Timer? timer;
  final started = DateTime.now();
  int setsDone = 0, repsDone = 0;
  static const restSecs = 60;

  Entry get cur => widget.entries[idx];
  Ex get ex => Data.byId[cur.id]!;

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  void tickRest() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() { rest--; if (rest <= 0) { t.cancel(); resting = false; advance(); } });
    });
  }

  void startTimed() {
    timer?.cancel();
    setState(() { timing = true; tleft = cur.secs; });
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() { tleft--; if (tleft <= 0) { t.cancel(); timing = false; completeSet(); } });
    });
  }

  void completeSet() {
    setsDone++; repsDone += cur.reps;
    final lastSet = set >= cur.sets;
    final lastEx = idx >= widget.entries.length - 1;
    if (lastSet && lastEx) { finish(); return; }
    setState(() { resting = true; rest = restSecs; });
    tickRest();
  }

  void advance() {
    if (set >= cur.sets) { idx++; set = 1; } else { set++; }
  }

  Future<void> finish() async {
    timer?.cancel();
    final mins = (DateTime.now().difference(started).inSeconds / 60).ceil().clamp(1, 600);
    await Store.addSession(Session(dkey(DateTime.now()), tr(widget.t.title), widget.program ? widget.t.id : '', mins, setsDone, repsDone, widget.entries.length));
    if (mounted) setState(() => finished = true);
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return Scaffold(backgroundColor: dark, body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.emoji_events, color: lime, size: 90),
        const SizedBox(height: 16),
        Text(tr('Workout complete'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(tr('Great work!'), style: const TextStyle(color: lime, fontSize: 18)),
        const SizedBox(height: 8),
        Text('$setsDone ${tr('Sets')} · $repsDone ${tr('Reps')}', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 26),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: lime, foregroundColor: dark, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)), onPressed: () => Navigator.pop(context), child: Text(tr('Close'))),
      ])))));
    }
    final total = widget.entries.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async { if (!didPop && await confirm(context, tr('Quit workout?'), '', tr('Quit'))) { timer?.cancel(); if (mounted) Navigator.pop(context); } },
      child: Scaffold(
        backgroundColor: bgGreen,
        appBar: AppBar(backgroundColor: bgGreen, elevation: 0, foregroundColor: dark, title: Text('${idx + 1} / $total', style: const TextStyle(fontWeight: FontWeight.w900)), bottom: PreferredSize(preferredSize: const Size.fromHeight(6), child: LinearProgressIndicator(value: (idx + (set - 1) / cur.sets) / total, color: lime, backgroundColor: Colors.white, minHeight: 6))),
        body: resting
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(tr('Rest'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text('$rest', style: const TextStyle(fontSize: 90, fontWeight: FontWeight.w900, color: dark)),
                const SizedBox(height: 10),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  OutlinedButton(onPressed: () => setState(() => rest = (rest - 15).clamp(1, 600)), child: const Text('-15')),
                  const SizedBox(width: 10),
                  OutlinedButton(onPressed: () => setState(() => rest += 15), child: const Text('+15')),
                ]),
                const SizedBox(height: 14),
                FilledButton(style: FilledButton.styleFrom(backgroundColor: dark, foregroundColor: lime), onPressed: () { timer?.cancel(); setState(() { resting = false; advance(); }); }, child: Text(tr('Skip rest'))),
                const SizedBox(height: 20),
                Text('${tr('Next')}: ${(set >= cur.sets && idx + 1 < total ? Data.byId[widget.entries[idx + 1].id]! : ex).cap}', style: const TextStyle(color: muted)),
              ]))
            : ListView(padding: const EdgeInsets.all(18), children: [
                ExAnim(ex),
                const SizedBox(height: 14),
                Text(ex.cap, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark)),
                const SizedBox(height: 4),
                Text('${tl(ex.bp)} · ${tl(ex.eq)}', textAlign: TextAlign.center, style: const TextStyle(color: muted)),
                const SizedBox(height: 14),
                Pad(color: dark, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  Column(children: [Text('${tr('Set')}', style: const TextStyle(color: Colors.white70)), Text('$set ${tr('of')} ${cur.sets}', style: const TextStyle(color: lime, fontSize: 22, fontWeight: FontWeight.w900))]),
                  Column(children: [Text(cur.secs > 0 ? tr('sec') : tr('reps'), style: const TextStyle(color: Colors.white70)), Text(cur.secs > 0 ? (timing ? '$tleft' : '${cur.secs}') : '${cur.reps}', style: const TextStyle(color: lime, fontSize: 22, fontWeight: FontWeight.w900))]),
                ])),
                const SizedBox(height: 4),
                SizedBox(width: double.infinity, child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: lime, foregroundColor: dark, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  onPressed: timing ? null : (cur.secs > 0 ? startTimed : completeSet),
                  child: Text(cur.secs > 0 ? tr('Start timer') : tr('Complete set'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                )),
                if (cur.secs > 0 && !timing) TextButton(onPressed: completeSet, child: Text(tr('Complete set'))),
              ]),
      ),
    );
  }
}
