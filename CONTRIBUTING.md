# Contributing

1. Open an issue before large changes.
2. `flutter pub get && dart format . && flutter analyze && flutter test` must pass.
3. Never commit secrets: OAuth client IDs of your own test apps, tokens, keystores, `.env` files.
4. Keep provider code behind the `StorageProvider` interface; core code must not import a concrete provider.
5. Small, focused pull requests with tests.
