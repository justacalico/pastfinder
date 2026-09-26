# Pastfinder

A paste service scanner. Pastfinder pulls the latest public pastes from
multiple paste sites, stores them locally, and gives you a searchable
library to explore.

## Sources

| Source | What is scanned |
|---|---|
| GitHub Gists | Public gist timeline (`api.github.com/gists/public`) |
| GitLab Snippets | Public snippets on gitlab.com |
| glot.io | Public code snippets |
| Pastebin | Public archive page (best effort, Cloudflare may block) |

Each source can be toggled individually on the Scanner tab. New pastes are
deduplicated across scans; bodies are fetched during the scan or on demand
from the detail view. The library keeps the newest 2000 pastes.

## Install

Prebuilt binaries for Linux, Windows, macOS, Android, iOS (AltStore) and a
web build are attached to each
[release](https://gitlab.com/HttpAnimations/pastfinder/-/releases). The web
version is also live on GitLab Pages.

## Build from source

```bash
flutter pub get
flutter run            # or: flutter build linux|windows|macos|web|apk
```

## License

[AGPL-3.0](LICENSE)
