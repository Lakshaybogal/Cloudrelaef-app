# WebDAV drive

The app can serve your pooled files over WebDAV so other programs on the same device can use them as a drive. Turn it on under **Drive** in the app. It is **off by default**.

## Security
- Listens on `127.0.0.1` only (this device). No LAN option yet.
- HTTP Basic auth: username `cloudrelaef`, a generated 24-character password stored in the OS keystore (never in the database or backups). "New password" restarts the server so the old one stops working.
- Requests whose `Host` header is not `localhost`/`127.0.0.1` are refused (blocks DNS-rebinding from web pages).
- Plain HTTP is fine on loopback. Do not expose the port (no port forwarding / tunnels) without adding TLS.

## Behaviour
| Request | What happens |
|---|---|
| `PROPFIND` | Lists the virtual folders and files (depth 0/1) with size, type, date, etag; root reports quota |
| `GET` / `HEAD` | Streams from whichever cloud holds the file. No range requests |
| `PUT` | New file is placed on the cloud with the most free space. Clients that send no length are buffered to a temp file first. Overwrite uploads the new file, then deletes the old one at the cloud |
| `DELETE` | File: moves to the app's Trash (recoverable). Folder: removes it and trashes its files |
| `MKCOL` | Creates a virtual folder |
| `MOVE` | Rename and/or move between folders (renames at the cloud). `Overwrite: F` honoured |
| `COPY` | Files only (re-uploads); folders return 501 |
| `LOCK` / `UNLOCK` | Accepted but nothing is locked (macOS Finder and Office require them) |

Files that two clouds hold under the same name appear as `name.ext` and `name (2).ext`. `.DS_Store`, `._*`, `Thumbs.db`, `desktop.ini` are accepted and discarded so they never reach your cloud.

## Mounting
- macOS: Finder -> Go -> Connect to Server -> `http://127.0.0.1:8765/`
- Linux: Files -> Other Locations -> `dav://127.0.0.1:8765/`, or `rclone`
- Windows: Explorer's built-in client only talks plain HTTP if enabled in the registry; `rclone mount` or WinSCP are simpler.

Not yet verified against real macOS/Windows clients (tested in-process with raw HTTP).
