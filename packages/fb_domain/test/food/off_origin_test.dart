import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'A28a OFF origin round-trips through createdFrom within the wire rule',
    () {
      for (final fiber in [false, true]) {
        for (final flags in [
          <HalalFlag>{},
          {HalalFlag.pork},
          {HalalFlag.alcohol, HalalFlag.unknownSource},
          HalalFlag.values.toSet(),
        ]) {
          final code = OffOrigin(fiberAssumed: fiber, halal: flags).encode();
          expect(RegExp(r'^[a-zA-Z]{1,32}$').hasMatch(code), isTrue);
          final back = OffOrigin.decode(code)!;
          expect(back.fiberAssumed, fiber);
          expect(back.halal, flags);
        }
      }
      expect(OffOrigin.decode('off')!.halal, isEmpty);
      expect(OffOrigin.decode('form'), isNull);
      expect(OffOrigin.decode('offUP'), isNull);
      expect(OffOrigin.decode('offline'), isNull);
    },
  );
}
