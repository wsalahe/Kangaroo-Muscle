import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n.dart';

String dkey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime dparse(String s) { final p = s.split('-'); return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2])); }

class Session {
  final String date, name, tpl;
  final int mins, sets, reps, count;
  Session(this.date, this.name, this.tpl, this.mins, this.sets, this.reps, this.count);
  Map toJson() => {'d': date, 'n': name, 'tp': tpl, 'm': mins, 's': sets, 'r': reps, 'c': count};
  factory Session.from(Map j) => Session(j['d'], j['n'], j['tp'] ?? '', j['m'], j['s'], j['r'], j['c']);
}

class Sched {
  final String date, tpl, time; // time may be ''
  Sched(this.date, this.tpl, this.time);
  Map toJson() => {'d': date, 'tp': tpl, 't': time};
  factory Sched.from(Map j) => Sched(j['d'], j['tp'], j['t'] ?? '');
}

class Store {
  static late SharedPreferences p;
  static final ValueNotifier<int> tick = ValueNotifier(0); // bump to refresh listeners
  static Future<void> init() async { p = await SharedPreferences.getInstance(); initLang(p); }
  static void _bump() => tick.value++;

  static bool get onboarded => p.getBool('onb') ?? false;
  static String get name => p.getString('name') ?? '';
  static String get gender => p.getString('gender') ?? 'male';
  static DateTime? get birth { final s = p.getString('birth'); return s == null ? null : dparse(s); }
  static int get age { final b = birth; if (b == null) return 0; final n = DateTime.now(); var a = n.year - b.year; if (n.month < b.month || (n.month == b.month && n.day < b.day)) a--; return a; }
  static double get height => p.getDouble('height') ?? 0;
  static double get weight => p.getDouble('weight') ?? 0;
  static String get mode => p.getString('mode') ?? 'home';
  static DateTime get start => dparse(p.getString('start') ?? dkey(DateTime.now()));

  static Future<void> setProfile({String? name, String? gender, DateTime? birth, double? height, double? weight, String? mode}) async {
    if (name != null) await p.setString('name', name);
    if (gender != null) await p.setString('gender', gender);
    if (birth != null) await p.setString('birth', dkey(birth));
    if (height != null) await p.setDouble('height', height);
    if (weight != null) await p.setDouble('weight', weight);
    if (mode != null) await p.setString('mode', mode);
    _bump();
  }
  static Uint8List? get photo { final s = p.getString('photo'); if (s == null || s.isEmpty) return null; try { return base64Decode(s); } catch (_) { return null; } }
  static Future<void> setPhoto(Uint8List? b) async { if (b == null) { await p.remove('photo'); } else { await p.setString('photo', base64Encode(b)); } _bump(); }
  static Future<void> setLang(String v) async { await p.setString('lang', v); langPref.value = v; _bump(); }
  static Future<void> finishOnboarding() async { await p.setBool('onb', true); if (p.getString('start') == null) await p.setString('start', dkey(DateTime.now())); _bump(); }

  static List<Session> get sessions {
    final s = p.getString('sessions');
    if (s == null) return [];
    return [for (final j in jsonDecode(s) as List) Session.from(j)];
  }
  static Future<void> addSession(Session x) async {
    final l = sessions..add(x);
    await p.setString('sessions', jsonEncode([for (final s in l) s.toJson()]));
    _bump();
  }

  static List<Sched> get scheds {
    final s = p.getString('scheds');
    if (s == null) return [];
    return [for (final j in jsonDecode(s) as List) Sched.from(j)];
  }
  static Future<void> _saveScheds(List<Sched> l) async { await p.setString('scheds', jsonEncode([for (final s in l) s.toJson()])); _bump(); }
  static Future<void> addSched(Sched s) async => _saveScheds(scheds..add(s));
  static Future<void> removeSched(Sched s) async => _saveScheds(scheds..removeWhere((x) => x.date == s.date && x.tpl == s.tpl && x.time == s.time));

  static Future<void> deleteAll() async {
    final keep = p.getString('lang');
    await p.clear();
    if (keep != null) await p.setString('lang', keep);
    initLang(p);
    _bump();
  }

  static List<Map> get chat {
    final s = p.getString('chat');
    return s == null ? [] : List<Map>.from(jsonDecode(s));
  }
  static Future<void> saveChat(List<Map> l) async => p.setString('chat', jsonEncode(l.length > 40 ? l.sublist(l.length - 40) : l));
}
