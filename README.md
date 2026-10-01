# CloudRelaef

Free, open-source, local-first app that pools your Google Drive, OneDrive and Dropbox storage into one place.

- **No account, no login, no server.** Your device is the server; the index lives in a local SQLite database.
- **Your clouds, your keys.** The app talks to Google Drive, OneDrive and Dropbox directly, using OAuth apps you create yourself (a guided one-time setup).
- **Database backups on all your clouds.** An encrypted snapshot of the index (not your files) is written to every connected cloud on an interval. Lose a device, or remove a cloud, and the others still have it.
- Android, iOS, Windows, macOS, Linux (Flutter).

> **Status: v0.1 in development.** Core logic is covered by 160+ automated tests against mocked cloud APIs. It has **not yet been tried against real Google/Microsoft/Dropbox accounts**, so expect rough edges and please report them.

## What it does
- Connect several cloud accounts and see one combined free-space number.
- Upload: each file goes to the account with the most free space. Download, rename, search, virtual folders, trash, move a file between clouds.
- Optional WebDAV drive: mount the pool in Finder/Explorer/rclone. Off by default, localhost only, password protected (see [docs/WEBDAV.md](docs/WEBDAV.md)).
- Back up the index (file names, folders, settings, trash state) to every cloud every few hours while the app is open. Restore on a new device with your recovery key.

## What it does not do
- It does **not** back up your files. Backups cover the index only, so if a cloud account is deleted, files that lived only there are gone.
- It does not run in the background when closed. On phones the OS decides; the app catches up when you open it.
- Two devices writing at once is not merged: you get a warning and choose.

## Security model
- Cloud sign-in tokens and the backup key live only in the OS keystore (Keychain, Keystore, DPAPI, Secret Service), never in the database or in backups.
- Backups are encrypted on-device (AES-256-GCM, random nonce per snapshot, header authenticated) before upload.
- **If you lose the recovery key, backups cannot be recovered.** The app makes you save it at setup.
- No telemetry, no analytics, no server of ours.
- Linux needs a Secret Service provider (gnome-keyring or KWallet).

## Develop
```bash
flutter pub get
dart run build_runner build   # only after changing lib/data/db/database.dart
flutter analyze
flutter test
flutter run -d linux          # or windows / macos / an Android or iOS device
```
Architecture and decisions: [docs/PLAN.md](docs/PLAN.md). Provider quirks: [docs/PROVIDERS.md](docs/PROVIDERS.md).

## Contributing / security
See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## License
[MIT](LICENSE)
