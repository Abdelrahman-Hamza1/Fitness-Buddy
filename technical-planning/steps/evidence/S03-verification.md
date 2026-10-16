# S03 verification — Backend host & HTTP conventions

Verified 2026-10-16 by Codex after independent code/security review (TD-061). All six exit criteria pass locally. The merge flow requires the `ci` gate on the exact squash SHA before main is fast-forwarded.

## Review

Separate reviewer agent `s03_independent_review` reviewed the whole diff against `origin/main` through `51adaee`, including inherited WP0–WP3/WP7. Security coverage included logging/telemetry, exception/content scrubbing, Sentry envelopes, trusted proxies, correlation, limits, secrets and container exposure.

- Round 1: one major (HTTP logging namespace guard missed ordinary extension calls), one minor (unsupported Accept values can produce plain-text error fallback), no blocker.
- Major fixed: guard targets the HTTP logging assembly, including referenced stubs. Separate broken fixtures call no-options `AddHttpLogging()` and `UseHttpLogging()`. Host meta tests check the required `ObjectPool<HttpLoggingInterceptorContext>` service; a positive registration test proves this works without an interceptor.
- Round 2: approved, no remaining blocker/major or regression. The reviewer inspected the scoped patch without modifying it. Minor recorded as backlog #53; current app JSON requests are unaffected.
- CI held the first squash (`467013e`): the request/shutdown test checked sink disposal immediately after WebApplicationFactory disposal. Host `RunAsync` can concurrently drain the service-provider graph, so a duplicate dispose can return first. The sink now signals actual disposal through a TaskCompletionSource; the test awaits it with a five-second bound and keeps its correlation, final-record and Disposed assertions.
- Round 3 independently approved this lifecycle-test fix; removing provider disposal forwarding still fails the test. Five focused shutdown-test runs pass. Production source/artifact is unchanged. Full `make check test` passes with the CI build settings (`GITHUB_ACTIONS=true`), all 161 .NET cases green.

## Exit criteria

| Criterion | Result and evidence |
|---|---|
| `make up`, conformant config and conformance check | ✅ Compose build/start waited for `/health/ready`; header-bearing `GET /v1/config` returned `200` with `{"minimumAppVersion":"0.1.0","featureFlags":{},"thresholds":{}}`. `FB_MIN_APP_VERSION=99.0.0 make up`, then an old-version config request, returned `200` with minimum `99.0.0`. `make down` removed container and network. `ConfigEndpointTests`, contract conformance and image config smoke pass. |
| 426 / validation 400 / safe 500 / request id | ✅ `Old_app_version_gets_426_upgrade_required_problem`, `Kill_switch_wins_over_a_malformed_platform_header`, `Invalid_body_gets_400_validation_failed_with_camelCase_errors`, unreadable-body theories, `Unhandled_exception_gets_500_with_traceId_and_X_Request_Id_and_no_internals`, inbound traceparent/ignored request-id tests and the status-header theories pass. Four shared golden problem bodies match the real server and map to Dart failures. A2 applies: the response id is always the trace id; inbound X-Request-Id is ignored. |
| No request content in logs | ✅ `No_canary_reaches_logs_activity_tags_events_status_or_metric_tags_for_200_400_426_429_500` captures formatted log messages, state, scopes, exception strings, activity tags/events/status and metric tags. Body/query/device/auth/exception canaries are absent. Sentry serialized-envelope test proves one 500 event, its original exception type, the header allowlist and no canaries. Recursive/aggregate exception, scopes/lifecycle, all-role provider, no HTTP logging/enrichment and positive sentinel tests pass. Tests use `Rule 09.4-logging`; AC-041 is not the logging requirement. |
| Local console traces; configurable OTLP | ✅ Actual `dotnet run` in Development returned config 200 and printed console `Activity.TraceId: 05acc30f9f926b724ee9db905883ba6d`, matching X-Request-Id; clean process exit 0. Image smoke likewise matched trace `8f9efb00eb0dce0107996b8d24c1b575`. `Otlp_exporter_sends_traces_when_the_endpoint_is_configured` receives nonempty protobuf at a real loopback `POST /v1/traces` after ForceFlush. Console exporter theory proves Development+enabled only (Testing remains off). |
| Architecture rules both pass and fail | ✅ Production rules load BuildingBlocks, Host and the explicit ModuleCatalog assemblies. Layer/module/Host/core boundaries, public surface, HTTP logging and injected time/IDs pass. Seventeen broken-fixture cases assert violations naming the offending type, including both HTTP logging extension calls and public request DTO consumption across modules. Clean fixture permits `Beta.Contracts` and public validation records. Framework targets include referenced stubs; empty future layers are permitted. |
| Non-root image; size measured | ✅ `make image-smoke`: configured/runtime UID **1654**, health/config 200, matching console trace, migrate exit 0, stop **0 s / exit 0** (<10 s). Engine image size **164,996,413 bytes** (157.35 MiB); gzipped `docker image save` archive **69,587,394 bytes** (66.36 MiB). Archive size is not registry transfer size. Runtime image id `sha256:476db3c6af00f7bba15eaf9a251ee1fbde03552fc6dc88f7b5cd68515fb04932`; review fix changes only tests/docs, not the runtime artifact. |

## Automated gates

- `make check test` passes with **161 .NET cases**, zero warnings/errors; Dart format/analyze/app-check, mobile/package/tool tests, contract freshness/lint/self-tests/breaking/conformance and APK hardening self-tests pass. The existing opt-in live mobile suite stays skipped when no API is running, as configured; the compose demo separately exercises the real API.
- `make gen-check` passes: no generated client or app-code drift.
- `bash -n tools/scripts/image-smoke.sh` and `docker compose -f infra/compose/docker-compose.yml config --quiet` pass; real image smoke and compose lifecycle pass.
- CI job `image` is in the required `ci.needs` list. Only the existing TD-060 Android skip is permitted; a failed/skipped image job fails the gate. Merge uses `tools/scripts/ci-status.sh <squash-sha>` and fast-forwards main to that same SHA only after success.

## Measurements and follow-ups

SDK **10.0.402**, ASP.NET runtime/packages **10.0.13**. OTel core/exporters/hosting **1.19.1**, instrumentation **1.19.0**, Sentry.AspNetCore **6.12.0**, ArchUnitNET **0.13.4**. Both Docker stages use verified manifest-list digests; smoke rejects an SDK-tag/global.json mismatch.

S05 must verify real proxy CIDRs, wire OTLP/Sentry and send all three client headers on synthetic config checks. The phone update-screen demo is batched with S07 under TD-037; automated version-gate tests and the real forced-minimum compose response pass here. Generic runtime schema validation of several endpoints remains backlog #21 (S26); S03 does not have those endpoints yet. Unsupported Accept negotiation is backlog #53.
