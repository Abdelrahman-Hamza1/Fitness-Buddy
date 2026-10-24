// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'about_info.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lazy package and pack reads; absent credits preserve the rest of About.

@ProviderFor(aboutInfo)
final aboutInfoProvider = AboutInfoProvider._();

/// Lazy package and pack reads; absent credits preserve the rest of About.

final class AboutInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<AboutInfo>,
          AboutInfo,
          FutureOr<AboutInfo>
        >
    with $FutureModifier<AboutInfo>, $FutureProvider<AboutInfo> {
  /// Lazy package and pack reads; absent credits preserve the rest of About.
  AboutInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aboutInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aboutInfoHash();

  @$internal
  @override
  $FutureProviderElement<AboutInfo> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AboutInfo> create(Ref ref) {
    return aboutInfo(ref);
  }
}

String _$aboutInfoHash() => r'894a0b45235b5f344fca318904d7ea4c4622f31f';
