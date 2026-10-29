import 'package:fb_mobile/features/design_preview/presentation/gallery/gallery_basics.dart';
import 'package:fb_mobile/features/design_preview/presentation/gallery/gallery_buddy.dart';
import 'package:fb_mobile/features/design_preview/presentation/gallery/gallery_input.dart';
import 'package:fb_mobile/features/design_preview/presentation/gallery/gallery_section.dart';

/// Every gallery section, in display order. Each public design-system
/// component is in one section's `covers` (a test fails when it isn't), so a
/// new component needs a section here.
final List<GallerySection> gallerySections = [
  ...gallerySectionsBasics,
  ...gallerySectionsInput,
  ...gallerySectionsBuddy,
];
