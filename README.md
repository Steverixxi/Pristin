# Pristin

A powerful macOS storage manager designed to locate, manage, and safely remove installed packages, libraries, and applications (including deep-system UNIX-style libraries and frameworks).
Pristin's ultimate goal is to theoretically restore your system to a pristine, "macOS-Sandboxed" state, ensuring no leftover software or stray files remain outside the official App Store Sandbox environment.

## Features

* **Sandbox Tracking** Identifies orphaned files and directories left outside official App Store sandboxes after an application is removed.
* **Localized Cache Layers** Tracks down deeply buried cache structures and accumulated temporary junk files that standard uninstallers miss.
* **Daemon & Launch Detection** Exposes lingering background services, launch agents, and operational fragments of long-gone apps.
* **Express Cache Purge** Instantly flushes volatile system caches and user-space buffers to reclaim active memory and disk space safely.

---

## Disclaimer

Pristin has been primarily tested and optimized on macOS systems set to English. 

If you are running your Mac in another language and notice any false positives, missing entries, or suboptimal scan results, we would love to hear from you! Please consider **opening an issue** with your system language details so we can improve localized scanning for everyone.

## OS Compatibility & Support

Pristin is built utilizing native SwiftUI frameworks and modern macOS architecture internals.

| macOS Version | Codename | Compatibility Status | Notes |
| :--- | :--- | :--- | :--- |
| macOS 26 | **Tahoe** | 🟢 Fully Supported |  |
| macOS 16 | **Sequoia** | 🟢 Fully Supported |  |

---

## Architecture & Development

Pristin is built as a native macOS application with a focus on speed, low memory footprint, and non-destructive scanning.
