import 'package:fb_text/fb_text.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

void main() {
  test('FD-021 identity keeps Latin repeats and folds other text', () {
    expect(identityKey('ＣÓＦＦＥＥ'), 'coffee');
    expect(identityKey('coffee'), isNot(identityKey('cofe')));
    expect(identityKey('أَرُزّ'), identityKey('ارز'));
    expect(identityKey('  الللّبن ـ ١ '), normalizeKey('  الللّبن ـ ١ '));
    expect(identityKey('Crème’s ﬀ ۰!'), 'cremes ff 0');
  });
  Glados(any.anyText, propertyRuns).test('FD-021 identityKey fixed point', (s) {
    expect(identityKey(identityKey(s)), identityKey(s));
  });
}
