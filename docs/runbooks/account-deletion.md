# Account deletion (B06)

`DELETE /v1/me` erases the authenticated guest or registered server account. The app owns
confirmation and local wiping (A35). The request has no body or target-user parameter and is
excluded from generic idempotency response caching.

## Completion and retries

Return204 means the database transaction committed: identities, devices, sessions, refresh hashes,
audit linkage, owned email challenges/address throttles, sync documents/history/receipts/fences,
Account intent, and user-owned Ops schedules/jobs/events/markers/replay bytes are gone. Shared
signing/wrapping keys, email pepper, dataset metadata, another account's data and global abuse
controls remain. A shared address challenge linked to another account belongs to that account.

All installed modules declare owned/global tables and an eraser in `IModule.UserData`. Buddy has
an explicit empty participant today. A future Usage/Catalog module must classify its actual storage
when installed. The real-database inventory test rejects unclassified tables or global tables with
user ownership; the coordinator refuses to run with a missing eraser.

The coordinator holds the global recovery lock and then the user lifecycle lock. Live Identity
checking, pending intent, database-only outbox participants, erasure and marker cleanup use one
transaction. A participant failure rolls everything back and permits authenticated retry. A known
pre-commit rollback reconciles the recovery generation while retaining the same exclusive lock;
an ambiguous commit never rolls back the external marker by guessing.

After success old access and refresh credentials fail. An old-token retry returns401, including
after a lost204.401 alone does not prove deletion: A35 must handle an uncertain network outcome
without treating every unrelated session expiry as confirmed account deletion.

## Requests and workers racing deletion

Identity credential mutations, sync, replay hits/new cached responses, scheduled work and queue
claims share the user lock and revalidate live state before effects. Queue discovery takes no row
lock; claimers acquire the owner's lock before the exact queue/schedule row and recheck its
identity/type/state/due time. Busy owners can be skipped so other users continue. Orphan work is
erased without invoking a user handler. Deletion purges processed markers before envelopes and
never adds a completion mapping after the final purge.

## Recovery and residuals

The global opaque recovery generation has no user mapping. Its protected live file is outside the
DB dump and the restorable identity-key bundle. A durably written new generation precedes erasure;
the matching database value commits with erasure. Missing, corrupt or mismatched state fails
closed. Neither a sync dataset UUID nor an old database dump proves that an account was not deleted.
The laptop's guarded backup/restore procedures are part of B06's delivery gate; see the laptop
runbook for the operator commands. B14 must preserve the same safety boundary on production.

Existing backups expire normally (laptop daily dumps: seven days; production maximum:30days).
Do not rewrite snapshots or remove shared keys for one account. Pre-deletion dumps cannot be used
for a direct live restore. An old snapshot needs an explicit offline sanitization procedure or an
owner-approved clean reset; it must not be opened to traffic by replacing the protected live marker.

Local email delivery files are short-lived credentials. Database erasure immediately prevents an
old code from authenticating the erased identity. Physical expiry is10minutes plus the next running
reaper sweep (at most one minute); a stopped laptop cannot erase files on a wall-clock deadline.
Startup must prune expired deliveries before traffic/readiness. These files are never backed up.

All verification uses synthetic accounts/stacks. Never delete the owner's account or reset a live
volume as a test. Routine backup and scratch restore checks preserve the live database.
