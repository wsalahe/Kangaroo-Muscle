import 'dart:convert';
import 'package:flutter/services.dart';

class Ex {
  final String id, name, bp, eq, target, mode;
  final List<String> sm, ins, cols;
  final int dur;
  Ex(this.id, this.name, this.bp, this.eq, this.target, this.mode, this.sm, this.ins, this.cols, this.dur);
  factory Ex.from(Map j) => Ex(j['id'], j['n'], j['bp'], j['eq'], j['t'], j['m'], List<String>.from(j['sm'] ?? []), List<String>.from(j['ins'] ?? []), List<String>.from(j['c'] ?? []), (j['d'] ?? 180) as int);
  bool get timed => cols.contains('mobility') || cols.contains('yoga') || cols.contains('hiit') || cols.contains('running');
  bool inMode(String m) => mode == 'both' || mode == m;
  String get cap => name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}

class Entry {
  final String id;
  final int sets, reps, secs; // secs > 0 means timed
  Entry(this.id, this.sets, this.reps, this.secs);
  Map toJson() => {'id': id, 's': sets, 'r': reps, 't': secs};
}

class Template {
  final String id, title; // title is an English key for tr()
  final String col;
  final List<String> parts; // body parts or collection tags
  final int mins;
  const Template(this.id, this.title, this.col, this.parts, this.mins);
}

const templates = <Template>[
  Template('full', 'Full body', 'strength', ['chest', 'back', 'upper legs', 'shoulders', 'waist', 'upper arms'], 40),
  Template('upper', 'Upper body', 'strength', ['chest', 'back', 'shoulders', 'upper arms', 'upper arms', 'chest'], 40),
  Template('lower', 'Lower body', 'strength', ['upper legs', 'upper legs', 'upper legs', 'lower legs', 'waist', 'lower legs'], 40),
  Template('core', 'Core and cardio', 'strength', ['waist', 'waist', 'waist', 'cardio', 'cardio', 'waist'], 25),
  Template('hiit', 'HIIT blast', 'hiit', ['#hiit', '#hiit', '#hiit', '#hiit', '#hiit', '#hiit'], 20),
  Template('mob', 'Mobility flow', 'mobility', ['#mobility', '#mobility', '#mobility', '#mobility', '#mobility', '#mobility', '#mobility'], 15),
  Template('yoga', 'Yoga and flexibility', 'yoga', ['#yoga', '#yoga', '#yoga', '#yoga', '#yoga', '#yoga'], 15),
  Template('run', 'Easy run and cardio', 'running', ['#running', '#running', '#hiit', '#running', '#hiit'], 25),
];

// Program: weekday (Mon=1..Sun=7) -> template id, '' = rest day.
const programWeek = {1: 'full', 2: 'hiit', 3: 'upper', 4: 'mob', 5: 'lower', 6: 'core', 7: ''};
const programTotal = 24; // 6 workouts a week for 4 weeks (rest day excluded)

class Data {
  static List<Ex> all = [];
  static Map<String, Ex> byId = {};
  static Future<void> load() async {
    final s = await rootBundle.loadString('assets/exercises.json');
    all = [for (final j in jsonDecode(s) as List) Ex.from(j)];
    byId = {for (final e in all) e.id: e};
  }

  static List<Ex> forMode(String m) => all.where((e) => e.inMode(m)).toList();

  static int _h(String s) {
    var h = 7;
    for (final c in s.codeUnits) { h = (h * 31 + c) & 0x7fffffff; }
    return h;
  }

  /// Builds the exercise list for a template, deterministic for (template, mode, seed).
  static List<Entry> build(Template t, String mode, int seed) {
    final pool = forMode(mode);
    final used = <String>{};
    final out = <Entry>[];
    var k = 0;
    for (final p in t.parts) {
      List<Ex> c;
      if (p.startsWith('#')) {
        c = pool.where((e) => e.cols.contains(p.substring(1))).toList();
      } else {
        c = pool.where((e) => e.bp == p && (p == 'cardio' || e.cols.contains('strength'))).toList();
        if (c.isEmpty) c = pool.where((e) => e.bp == p).toList();
      }
      c = c.where((e) => !used.contains(e.id)).toList();
      if (c.isEmpty) continue;
      final e = c[_h('${t.id}$mode$seed${k++}') % c.length];
      used.add(e.id);
      if (e.timed) {
        out.add(Entry(e.id, 2, 0, e.cols.contains('hiit') || e.cols.contains('running') ? 40 : 30));
      } else {
        out.add(Entry(e.id, 3, 10, 0));
      }
    }
    return out;
  }
}
