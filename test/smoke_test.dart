import 'package:flutter_test/flutter_test.dart';
import 'package:kangaroo_muscle/l10n.dart';

void main() {
  test('translation falls back to key', () {
    expect(tr('zzz-unknown-key'), 'zzz-unknown-key');
  });
}
