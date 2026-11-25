import 'package:flutter_test/flutter_test.dart';
import 'package:kangaroo_muscle/l10n.dart';
import 'package:kangaroo_muscle/main.dart';

void main() {
  test('translation falls back to key', () {
    expect(tr('zzz-unknown-key'), 'zzz-unknown-key');
  });
  test('markdown is stripped', () {
    final o = stripMd('**Hi**\n| a | b |\n|---|---|\n| 1 | 2 |\n- item');
    expect(o.contains('*'), false);
    expect(o.contains('|'), false);
  });
}
