import 'package:fb_mobile/core/api/api_origin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AC-003 the guest email-link start is authenticated, the plain '
      'email start stays public', () {
    final api = Uri.parse('https://api.example.test');
    expect(
      isPublicApiRequest(api.resolve('/v1/auth/link/email/start')),
      isFalse,
    );
    expect(isPublicApiRequest(api.resolve('/v1/auth/link/email')), isFalse);
    expect(isPublicApiRequest(api.resolve('/v1/auth/email/start')), isTrue);
  });
}
