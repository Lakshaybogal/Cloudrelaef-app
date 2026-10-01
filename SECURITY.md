# Security

Please report vulnerabilities privately through GitHub's "Report a vulnerability" (Security tab), not in public issues.

Design notes:
- Refresh tokens and the backup key are stored only in the OS keystore, never in the SQLite database or in backups.
- Backups are encrypted on-device before upload. Losing the recovery key makes backups unrecoverable.
- The app has no server and collects no telemetry.
