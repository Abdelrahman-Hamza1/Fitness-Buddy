import 'dart:io';

import 'package:fb_mobile/core/photos/photo_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('A69 fix-check: only listed plain files are deleted; never a '
      'directory or an unlisted file', () async {
    final root = await Directory.systemTemp.createTemp('fb-photo-owned');
    addTearDown(() => root.delete(recursive: true));
    final owned = OwnedPhotoFiles(File('${root.path}/support/owned.json'));
    final picked = await File('${root.path}/scaled_IMG_1.jpg').create();
    final leftover = await File('${root.path}/IMG_2.jpg').create();
    final unlisted = await File('${root.path}/scaled_other.jpg').create();
    final dir = await Directory('${root.path}/a-folder').create();

    // Used and released: deleted at once.
    await owned.own(picked.path);
    await owned.release(picked.path);
    expect(picked.existsSync(), isFalse);

    // A kill mid-read leaves it listed: the next sweep deletes it.
    await owned.own(leftover.path);
    await owned.own(dir.path);
    await OwnedPhotoFiles(File('${root.path}/support/owned.json')).sweep();
    expect(leftover.existsSync(), isFalse);
    expect(dir.existsSync(), isTrue);
    expect(unlisted.existsSync(), isTrue);

    // Releasing an unlisted path deletes nothing.
    await owned.release(unlisted.path);
    expect(unlisted.existsSync(), isTrue);
  });
}
