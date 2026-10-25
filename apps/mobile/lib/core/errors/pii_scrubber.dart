import 'package:sentry_flutter/sentry_flutter.dart';

/// Removes anything that could carry user content or identify the user from
/// Sentry events and breadcrumbs (CLAUDE.md rule 6, `09` §4, S06 plan D12,
/// A5). Allow-list style: only what is known to be safe is kept.
///
/// Kept: exception types and stack traces, level, safe tags, release and
/// environment, the allow-listed fields of the device, OS, runtime, app,
/// culture, GPU and trace contexts, breadcrumb categories, and route names on
/// navigation breadcrumbs.
///
/// Dropped: exception messages (they can quote user input), the user (never
/// set, not even the device id), the request, `extra`, the server name,
/// other contexts (e.g. Flutter's error details, which can describe widgets
/// and their text), message parameters, breadcrumb messages and data. Kept
/// contexts are rebuilt field by field, so per-install ids (the device name,
/// `device_unique_identifier`, `device_app_hash`, a native device `id`) and
/// any field the SDK doesn't model (its `unknown` map) never leave.
///
/// Native (Java/NDK) capture is disabled (A11 D12); Dart envelopes use
/// the native transport after this scrubber.
abstract final class PiiScrubber {
  /// What an exception message is replaced with.
  static const scrubbed = '[scrubbed]';

  /// Contexts kept on an event (by their Sentry key). The runtimes are kept
  /// as the list `Contexts` holds them in.
  static const Set<String> keptContexts = {
    SentryDevice.type,
    SentryOperatingSystem.type,
    SentryRuntime.listType,
    SentryApp.type,
    SentryCulture.type,
    SentryGpu.type,
    SentryTraceContext.type,
  };

  /// Data keys kept on navigation breadcrumbs: the route names and the
  /// navigation kind, never route arguments.
  static const Set<String> keptNavigationData = {'state', 'from', 'to'};

  /// Only app-controlled, enumerated tag values may survive native enrichment.
  static const Map<String, Set<String>> keptTags = {
    'flavor': {'dev', 'staging', 'prod'},
  };

  /// `beforeSend`: scrubs [event] in place and returns it.
  static SentryEvent scrubEvent(SentryEvent event, Hint hint) {
    event
      ..user = null
      ..request = null
      ..serverName = null
      ..tags = {
        for (final entry in (event.tags ?? <String, String>{}).entries)
          if (keptTags[entry.key]?.contains(entry.value) ?? false)
            entry.key: entry.value,
      }
      // `extra` is deprecated but still sent; it must stay empty.
      // ignore: deprecated_member_use
      ..extra = null;
    final message = event.message;
    if (message != null) {
      // Packages may also capture messages: free text is never trusted.
      event.message = SentryMessage(scrubbed);
    }
    for (final exception in event.exceptions ?? const <SentryException>[]) {
      if (exception.value != null) exception.value = scrubbed;
      final mechanism = exception.mechanism;
      if (mechanism != null) {
        mechanism
          ..description = null
          ..data = null;
      }
    }
    _scrubContexts(event.contexts);
    final breadcrumbs = event.breadcrumbs;
    if (breadcrumbs != null) {
      event.breadcrumbs = [
        for (final crumb in breadcrumbs) ?scrubBreadcrumb(crumb, hint),
      ];
    }
    return event;
  }

  /// Keeps only [keptContexts], each rebuilt from its allow-listed fields.
  /// A kept key whose value isn't the SDK's type is dropped.
  static void _scrubContexts(Contexts contexts) {
    final kept = {
      SentryDevice.type: switch (contexts[SentryDevice.type]) {
        final SentryDevice d => _device(d),
        _ => null,
      },
      SentryOperatingSystem.type:
          switch (contexts[SentryOperatingSystem.type]) {
            final SentryOperatingSystem os => SentryOperatingSystem(
              name: os.name,
              version: os.version,
              build: os.build,
              kernelVersion: os.kernelVersion,
              rooted: os.rooted,
              theme: os.theme,
            ),
            _ => null,
          },
      SentryRuntime.listType: switch (contexts[SentryRuntime.listType]) {
        final List<Object?> runtimes => [
          for (final r in runtimes.whereType<SentryRuntime>())
            SentryRuntime(
              key: r.key,
              name: r.name,
              version: r.version,
              compiler: r.compiler,
              build: r.build,
            ),
        ],
        _ => null,
      },
      SentryApp.type: switch (contexts[SentryApp.type]) {
        final SentryApp app => SentryApp(
          name: app.name,
          version: app.version,
          identifier: app.identifier,
          build: app.build,
          buildType: app.buildType,
          startTime: app.startTime,
          appMemory: app.appMemory,
          inForeground: app.inForeground,
          textScale: app.textScale,
        ),
        _ => null,
      },
      SentryCulture.type: switch (contexts[SentryCulture.type]) {
        final SentryCulture c => SentryCulture(
          calendar: c.calendar,
          displayName: c.displayName,
          locale: c.locale,
          is24HourFormat: c.is24HourFormat,
          timezone: c.timezone,
        ),
        _ => null,
      },
      SentryGpu.type: switch (contexts[SentryGpu.type]) {
        final SentryGpu g => SentryGpu(
          name: g.name,
          vendorId: g.vendorId,
          vendorName: g.vendorName,
          memorySize: g.memorySize,
          apiType: g.apiType,
          multiThreadedRendering: g.multiThreadedRendering,
          version: g.version,
          npotSupport: g.npotSupport,
        ),
        _ => null,
      },
      SentryTraceContext.type: switch (contexts[SentryTraceContext.type]) {
        final SentryTraceContext t => SentryTraceContext(
          traceId: t.traceId,
          spanId: t.spanId,
          parentSpanId: t.parentSpanId,
          sampled: t.sampled,
          operation: t.operation,
          status: t.status,
          origin: t.origin,
        ),
        _ => null,
      },
    };
    assert(
      kept.keys.toSet().containsAll(keptContexts) &&
          keptContexts.containsAll(kept.keys),
      'every kept context is rebuilt',
    );
    contexts.clear();
    for (final MapEntry(:key, :value) in kept.entries) {
      if (value != null) contexts[key] = value;
    }
  }

  /// The device without its name, ids or boot time (a fingerprint).
  static SentryDevice _device(SentryDevice d) => SentryDevice(
    family: d.family,
    model: d.model,
    modelId: d.modelId,
    arch: d.arch,
    batteryLevel: d.batteryLevel,
    orientation: d.orientation,
    manufacturer: d.manufacturer,
    brand: d.brand,
    screenHeightPixels: d.screenHeightPixels,
    screenWidthPixels: d.screenWidthPixels,
    screenDensity: d.screenDensity,
    screenDpi: d.screenDpi,
    online: d.online,
    charging: d.charging,
    lowMemory: d.lowMemory,
    simulator: d.simulator,
    memorySize: d.memorySize,
    freeMemory: d.freeMemory,
    usableMemory: d.usableMemory,
    storageSize: d.storageSize,
    freeStorage: d.freeStorage,
    externalStorageSize: d.externalStorageSize,
    externalFreeStorage: d.externalFreeStorage,
    processorCount: d.processorCount,
    cpuDescription: d.cpuDescription,
    processorFrequency: d.processorFrequency,
    deviceType: d.deviceType,
    batteryStatus: d.batteryStatus,
    supportsVibration: d.supportsVibration,
    supportsAccelerometer: d.supportsAccelerometer,
    supportsGyroscope: d.supportsGyroscope,
    supportsAudio: d.supportsAudio,
    supportsLocationService: d.supportsLocationService,
  );

  /// `beforeBreadcrumb`: keeps the category, type, level and time; drops the
  /// message and data, except route names on navigation breadcrumbs.
  static Breadcrumb? scrubBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
    if (breadcrumb == null) return null;
    final data = breadcrumb.data;
    breadcrumb
      ..message = null
      ..data = breadcrumb.category == 'navigation' && data != null
          ? {
              for (final MapEntry(:key, :value) in data.entries)
                if (keptNavigationData.contains(key) && value is String)
                  key: value,
            }
          : null;
    return breadcrumb;
  }
}
