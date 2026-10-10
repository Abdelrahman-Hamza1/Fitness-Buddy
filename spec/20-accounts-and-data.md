# 20 — Accounts, Sync, Offline & Data

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-007, D-008, D-018, D-026, D-049, D-059, D-065, D-067._

## 1. Accounts (D-059)

- **AC-001** `[R1]` Sign in with **Google**, **email** (with verification), or **Apple** (iOS; required by App Store rules when Google sign-in is offered).
- **AC-002** `[R1]` **Guest mode**: the app is fully usable without an account. Data stays on the device. A gentle, dismissible prompt suggests signing in to keep data safe: after the first week, and before risky actions such as account-only features. At most once a week.
- **AC-003** `[R1]` Signing up from guest mode carries all existing data into the account.
- **AC-004** `[R1]` Signing out asks whether to keep or remove the local copy on that device.

## 2. Sync (D-008)

- **AC-010** `[R1]` Everything is synced to the account and available on every signed-in device: diary, foods, memory, batches, targets, goals, weigh-ins, measurements, workouts, settings, chat history. The only exception is **progress photos**, which never leave the device (WB-050).
- **AC-011** `[R1]` Reinstalling the app or switching phones and signing in restores everything (SC-6).
- **AC-012** `[R1]` Changes made offline sync automatically when the connection returns. If the same entry was changed on two devices, **the latest change wins**, and nothing is silently lost: the overwritten version stays recoverable in that entry's history for 30 days.
- **AC-013** `[R1]` A small, unobtrusive indicator shows sync status when something hasn't synced yet.

## 3. Offline behaviour (D-007, D-049)

| Works offline | Needs connection |
|---|---|
| Diary viewing and manual editing | Buddy (AI): messages queue as pending (AI-047) |
| Food search (history, your foods, common foods, must-cover list, FD-023) | Full database search |
| Quick-add chips, saved meals, open batches | Barcode lookup of products not seen before (the scan is queued) |
| Weigh-ins, measurements | Label photo reading (photo is queued) |
| Workout logging by form, templates, history | Sign-in, sync |
| All charts and summaries of synced data | Weekly review generation |

- **AC-020** `[R1]` Anything queued offline shows clearly as pending and is processed automatically when back online. Results that need confirmation become proposals (D-079).

## 4. Data ownership

- **AC-030** `[R1]` **Export**: all data as CSV (one file per type, e.g. diary, weigh-ins, workouts) and JSON (everything), from settings (D-067).
- **AC-031** `[R1]` **Account deletion** in the app: explains what will be deleted, requires confirmation, and permanently deletes all server-side data within 30 days. Local data on the device is removed at the same time.
- **AC-032** `[R1]` The "Buddy remembers" screen (AI-082) shows everything Buddy has learned, and each item can be edited or removed.
- **AC-033** `[R1]` Chat history can be cleared without affecting diary data.

## 5. Privacy promises

These are product commitments. Technical planning must choose providers and designs that keep them.

- **AC-040** `[R1]` User data is **never sold** and **never used for ads** (D-041).
- **AC-041** `[R1]` What goes to the AI provider: the user's message or photo, plus the minimum context needed (e.g. relevant personal foods, defaults, today's targets). Account identity details (email, name) are **not** sent (D-018).
- **AC-042** `[R1]` The AI provider must not use user data to train its models, and must not keep it longer than needed to process the request.
- **AC-043** `[R1]` Progress photos are never sent anywhere (WB-050).
- **AC-044** `[R3]` A privacy policy in plain language (English and Arabic) is available in the app and on the store listing.

## Open questions

None currently.
