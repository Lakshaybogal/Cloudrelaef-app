# CloudRelaef

Free, open-source, local-first app that pools your Google Drive, OneDrive and Dropbox storage into one place.

- **No account, no login, no server.** Your device is the server; the index lives in a local SQLite database.
- **Your clouds, your keys.** The app talks to Google Drive, OneDrive and Dropbox directly using your own OAuth apps.
- **Database backups on all your clouds.** An encrypted snapshot of the index (not your files) is written to every connected cloud on an interval, so losing a device or a cloud doesn't lose your setup.
- Android, iOS, Windows, macOS, Linux (Flutter).

> Status: early development (M0 bootstrap). See [docs/PLAN.md](docs/PLAN.md) for the design and milestones.

## Develop
```bash
flutter pub get
flutter analyze
flutter test
flutter run -d linux   # or windows / macos / an Android or iOS device
```

## Contributing / security
See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## License
[MIT](LICENSE)
