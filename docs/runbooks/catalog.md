# Catalog releases (B07)

Build the reviewed-only release without editing curator data:

```sh
make catalog-pack
```

Output is `build/catalog/catalog.db` plus `build/catalog/release/`. The currently shipped release
has basics only; A04 dishes remain drafts under TD-074 and exercise/city rows await A05b. Do not
publish a dev draft pack. Do not use `make catalog` unless the app implementer is updating data.

For a locally configured migrate role, supply `ConnectionStrings__Migrator` and
`Recovery__Directory` through private environment/configuration and run:

```sh
make catalog-import CATALOG_DIR=build/catalog
```

This uses the existing `migrate` role, its migrations and global recovery maintenance fence.
Ordinary API/worker processes cannot import. Initializing a genuinely new recovery state is a
separate explicit operation; importing never guesses or overwrites a missing marker.

On the prepared private phone stack, use its installed controller:

```sh
python3 ~/.local/share/fitness-buddy/phone-server/phone-server.py catalog-import --catalog-dir "$PWD/build/catalog"
```

Or `make serve-phone-catalog-import` from the repo. This adds a temporary read-only bind to a
one-shot migrate container, keeps credentials on its existing private environment/mounts, opens
no port, and removes the temporary overlay on success or failure. Existing traffic waits behind
the recovery maintenance fence during publication. Run only a current main image containing B07.

Import snapshots bounded bytes, verifies fixed filenames/schema/checksums/counts/content hash,
rejects draft/unknown/oversized/inconsistent inputs and stable identity conflicts, then commits
all data plus pack and latest pointer atomically. Repeating identical version+content+pack succeeds
without changes. Reusing a version for different pack bytes fails even if food content is unchanged.
A new release is monotonic. Removed foods retire from search while detail remains available;
all published packs remain downloadable. On failure, the previous publication remains current.
Release format/schema changes must coordinate with `contracts/catalog` and the A05 producer.
Current HTTP nutrients are per100g; the importer rejects per100ml releases until that basis is
explicit in the API. This does not affect the current A05 output.

Use a guest or registered bearer plus normal client headers to check:

- `/v1/catalog/packs/latest`: expected version, relative URL, sha256 and sizeBytes.
- Download that URL with the same headers; check its byte length and SHA256 before installing.
- `/v1/foods/search?query=rice&limit=20`: stable keys/nutrients; an old cursor gets400 after import.

Do not put bearer tokens on a shell command line or in logs. The app owns offline-first merge and
atomic SQLite installation (A24); diary snapshots are unaffected by catalog updates.

The pack and reference rows are global Postgres data, included in normal dumps and scratch
restore checks. They survive account deletion. No OFF data enters release tables. B13/B14 may
move binary delivery to object storage, retaining immutable version/checksum semantics and the
existing deletion-safe backup barrier. Search production latency must be remeasured in B14.
