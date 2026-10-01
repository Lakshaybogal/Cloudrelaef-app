# Open-source local-first app: plan

Status: **draft for approval**. Lives in the private repo only as a planning doc. Move it to the new public repo when that exists. Nothing here changes the current product.

## Product in one paragraph
A free, MIT-licensed Flutter app (Android, iOS, Windows, macOS, Linux). No account, no login, no hosted backend, no server database. The user's device is the server: it keeps a local SQLite database, talks to Google Drive, OneDrive and Dropbox directly, and on an interval writes an **encrypted snapshot of the database only** (not the files) to every connected cloud. If the device is lost or one cloud is removed, the user installs the app, connects any one cloud, enters their recovery key, and gets the index back.

## Decisions (fixed)
| Topic | Decision |
|---|---|
| Framework | Flutter (one codebase, 5 platforms) |
| License | MIT |
| Providers (v1) | Google Drive, OneDrive, Dropbox |
| Repo | New public repo, fresh history. Port ideas from the private repo, not its history |
| OAuth | User brings own OAuth apps (BYO keys); PKCE, no client secret |
| Backups | Encrypted SQLite snapshot only, written to **all** connected clouds. File contents are not replicated |
| Server | None. No Postgres, Redis, auth, Sentry, billing, multi-user, admin |

## What we keep from the private repo, and what we drop
Keep as design reference, rewritten in Dart:
- `StorageProvider` interface (auth URL, exchange code, refresh, quota, list with cursor, chunked upload, streamed download, delete, rename) and the registry pattern.
- Placement engine (`most_free_space`, safety margin) and strategy registry.
- Virtual folders, trash, search, quota forecast, per-account health, per-provider quirks (`docs/provider-notes.md`).

Drop: users/auth/2FA, invites, admin, billing, plans, audit log, abuse limits, Redis token cache, ARQ worker, WebDAV, MCP server, hosted AI. AI features are out of scope for v1 (can return later as bring-your-own-key).

Safety rule for the new repo: copy no `.env`, tokens, keys or git history from the private repo. Run secret scanning before the first public push.

## Architecture
```
lib/
  core/            result/errors, logging (token redaction), clock, ids
  data/
    db/            drift (SQLite) schema + migrations, DAOs
    secure/        flutter_secure_storage wrapper (refresh tokens, recovery key)
  providers/       storage_provider.dart (interface), registry, google_drive/, onedrive/, dropbox/, http (retry/backoff)
  auth/            OAuth PKCE flow per platform, token refresh + in-memory access-token cache
  services/        accounts, sync (index a cloud), files (upload/download/transfer), placement, trash, folders, quota/forecast
  backup/          snapshot (export DB, compress, encrypt), uploader (all clouds), restore, conflict check
  ui/              screens, widgets, state (Riverpod)
test/              unit (placement, crypto, snapshot, provider adapters with fake HTTP), integration
```

### Local data
- SQLite via `drift`. Tables mirror the private schema minus users: `linked_accounts`, `folders`, `files`, `quota_snapshots`, `app_settings`, plus `backup_runs` (cloud, time, snapshot id, result).
- Secrets (refresh tokens, backup key) go in the OS keystore via `flutter_secure_storage`, **never** in SQLite and never in snapshots.
- Snapshots hold only the index and settings: no tokens. After a restore the user re-authorizes each cloud (one tap each).

### OAuth without a backend
- Authorization Code + PKCE, public client, no secret.
- Desktop: loopback redirect (`http://127.0.0.1:<port>`) plus system browser. Mobile: custom-scheme or app-link redirect via `flutter_appauth`.
- BYO keys: a setup wizard per provider with step-by-step instructions and the exact redirect URI to paste; client IDs stored locally. (Bundled default client IDs can be added later without changing the design.)

### Backup / restore
1. **Trigger:** on an interval (default 6 h, configurable), after significant changes (debounced), on app open if overdue, and manually. Mobile uses the OS background scheduler (`workmanager`) as best effort; the app also catches up on open. Nothing is promised while the app is closed beyond what the OS grants.
2. **Snapshot:** SQLite `VACUUM INTO` a temp file, so it is consistent -> gzip -> encrypt.
3. **Crypto:** random 256-bit master key generated at setup, shown once as a recovery phrase/QR for the user to save, stored in the keystore. AES-256-GCM (or XChaCha20-Poly1305), fresh nonce per snapshot, header with format version, app version, schema version, snapshot id, device id, monotonic counter. Optional: wrap the key with a user passphrase (Argon2id).
4. **Upload:** to every active cloud into an app folder (`/UniCloudBackup/`, using the app-folder scope where the provider has one). Write temp name then rename, keep the last N (default 10) per cloud, prune older ones. One cloud failing does not fail the others; each result is recorded and shown.
5. **Restore:** new device -> connect any one cloud -> enter recovery key -> pick the newest valid snapshot (cross-check all connected clouds, pick highest counter) -> decrypt, verify, schema-migrate, replace the local DB -> re-authorize remaining clouds -> optional re-sync to reconcile with actual cloud contents.
6. **Two devices:** single-writer assumption. On backup, if a cloud holds a snapshot with a newer counter from another device, warn and ask (keep mine / restore theirs) instead of overwriting silently.
7. **Honest limit:** snapshots restore the index, folders and settings. File contents live only in each cloud; if a cloud is deleted, those files are gone (a re-sync just drops them).

## Milestones
| # | Scope | Done when |
|---|---|---|
| M0 | Repo bootstrap: Flutter 5-platform skeleton, MIT license, CI (analyze, test, build), secret scanning, CONTRIBUTING, SECURITY.md | CI green on a hello-world app |
| M1 | Local DB (drift) + secure storage + provider interface + fake provider + placement + unit tests | Placement and DB tests pass |
| M2 | OAuth PKCE + BYO-keys wizard + Google Drive adapter: connect, quota, list, upload, download, delete, rename | Real Drive account works end to end on desktop + Android |
| M3 | Dropbox and OneDrive adapters, quirks from provider-notes, adapter contract tests shared by all three | Same contract suite passes for all three |
| M4 | Unified file UI: pool dashboard, files, search, folders, trash, transfer between clouds, health | Core flows usable on phone and desktop layouts |
| M5 | Backup/restore: snapshot, encryption, recovery key, multi-cloud upload, retention, restore, two-device warning, background scheduling | Wipe app, restore from a single cloud, index identical |
| M6 | Hardening and release: token redaction audit, crash-safe writes, migrations tests, signed builds, installers (MSI/DMG/AppImage, APK/AAB, TestFlight), docs, README | v0.1.0 tagged |

Later (not v1): bundled OAuth client IDs, more providers, file replication across clouds, multi-device merge, bring-your-own-key AI.

## Risks
- **iOS/Android background limits:** interval backups are best effort when the app is closed. Mitigation: catch-up on open, clear "last backup" status and warnings after N days.
- **BYO OAuth friction and Google quotas:** Drive scopes in an unverified/testing app have token expiry (testing mode refresh tokens expire in 7 days) and user caps. The wizard must tell users to publish their own OAuth app to "In production" or accept re-auth. This is the biggest usability risk and is the reason to add bundled IDs later.
- **Lost recovery key = unrecoverable backups.** Mandatory save-the-key step at setup, with a confirm-you-saved check.
- **Provider API drift/rate limits:** contract tests plus per-provider retry/backoff.
- **Public-repo hygiene:** no secrets or private history; threat model for local token storage documented in SECURITY.md.

## Next step
On approval: you create the empty public repo (MIT) and tell me the name; I add it to the session and execute M0 -> M1, pushing in small commits. Open question for you: confirm app name and bundle id (current working name "UniCloud", package `app.unicloud`?).
