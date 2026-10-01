# Provider notes

All three use Authorization Code + PKCE with a loopback redirect `http://localhost:53682/` (register exactly this at the provider). The in-app wizard shows the steps.

## Google Drive
- Create an OAuth client of type **Desktop app**. Google still needs the client secret for token exchange; for installed apps it is not confidential.
- Send `access_type=offline` and `prompt=consent`, or no refresh token comes back.
- Default scope `drive.file`: the app only sees files it creates. Widen to `drive` in your own OAuth app if you want to see everything.
- **Testing-mode apps expire refresh tokens after 7 days.** Publish your OAuth app ("In production") to avoid weekly reconnects.
- Resumable uploads in 8 MiB chunks (multiple of 256 KiB). Rate limits arrive as 403 `rateLimitExceeded` or 429 and are retried.

## OneDrive (personal)
- Tenant `consumers`, scopes `Files.ReadWrite.AppFolder offline_access User.Read`. Files live in `OneDrive/Apps/<your app name>/`.
- Refresh tokens **rotate**: every refresh returns a new one, which the app stores.
- Quota can be refused with only the app-folder scope (403); the app then estimates usage from indexed files.
- Upload sessions in 10 MiB chunks (multiple of 320 KiB); the upload URL is pre-authenticated so the bearer token is never sent to it. Downloads follow Graph's 302 by hand so the token is never forwarded to the redirect host.
- Forbidden name characters become `_`.

## Dropbox
- "App folder" access; the app folder is the root for the API. Scopes: `files.metadata.read/write`, `files.content.read/write`, `account_info.read`.
- Register `http://localhost:53682/` as a redirect URI in the app console.
- Files up to 8 MiB upload in one request, larger ones use upload sessions with 8 MiB chunks. Header arguments are ASCII-escaped.
- Name clashes on upload are auto-renamed; rename onto an existing name returns 409.
- Development-status apps are limited to 50 users, which does not matter for your own app.

## Backup files
Snapshots are named `cloudrelaef-backup-<counter>-<device>.crb` in each cloud's app folder and are excluded from the file index.
