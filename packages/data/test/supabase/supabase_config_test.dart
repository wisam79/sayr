import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_data/src/supabase/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test('creates config with valid parameters', () {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
      );

      expect(config.url, 'https://example.supabase.co');
      expect(config.anonKey, 'test-anon-key');
    });

    test('throws AssertionError when url is empty', () {
      expect(
        () => SupabaseConfig(url: '', anonKey: 'key'),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when anonKey is empty', () {
      expect(
        () => SupabaseConfig(url: 'https://example.supabase.co', anonKey: ''),
        throwsAssertionError,
      );
    });
  });
}
