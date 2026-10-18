import 'package:flutter_test/flutter_test.dart';
import 'package:tradeproof/services.dart';

void main() {
  test('credential seal is stable and tamper-evident', () {
    final a = credHash('Electrician', 'Jack', 'City & Guilds', '2026-01-01');
    expect(a, credHash('Electrician', 'Jack', 'City & Guilds', '2026-01-01'));
    expect(a == credHash('Electrician', 'Jack', 'City & Guilds', '2026-01-02'), isFalse);
    expect(a.length, 64);
  });
}
