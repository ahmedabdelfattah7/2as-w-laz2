# 2as w Laze2  (قص ولزق)

*"Remembers it, so you don't."*

A small macOS clipboard history utility. Press **⌘⇧V** anywhere, type to filter,
press **Enter**, and the item is pasted straight into whatever app you were in.

It lives in the menu bar, has no Dock icon, and does nothing while you are not
using it.

[![Download](https://img.shields.io/badge/Download-.dmg-E5682B?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/ahmedabdelfattah7/2as-w-laz2/releases/latest/download/2as-w-Laze2.dmg)
[![Latest release](https://img.shields.io/github/v/release/ahmedabdelfattah7/2as-w-laz2?style=for-the-badge&color=F9C94F)](https://github.com/ahmedabdelfattah7/2as-w-laz2/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-555?style=for-the-badge)](LICENSE)

## Install

Apple Silicon and Intel, macOS 13 or later.

> **Heads up:** this app is not signed by Apple, so macOS will show
> **"Apple could not verify 2as w Laze2 is free of malware"** and refuse to
> open it. That is expected for any app distributed outside the App Store
> without a $99/year Apple Developer account. The install below clears it.
>
> **Do not double-click the app inside the DMG.** A mounted DMG is read-only,
> so the fix cannot be applied there. Copy it out first.

### Easiest: one command

Paste this into Terminal. It downloads, installs, unblocks, and launches:

```bash
curl -fL -o /tmp/laze2.dmg https://github.com/ahmedabdelfattah7/2as-w-laz2/releases/latest/download/2as-w-Laze2.dmg && hdiutil attach -quiet /tmp/laze2.dmg && ditto "/Volumes/2as w Laze2/2as w Laze2.app" "/Applications/2as w Laze2.app" && hdiutil detach -quiet "/Volumes/2as w Laze2" && xattr -dr com.apple.quarantine "/Applications/2as w Laze2.app" && open "/Applications/2as w Laze2.app"
```

### Or by hand

1. **[Download the DMG](https://github.com/ahmedabdelfattah7/2as-w-laz2/releases/latest/download/2as-w-Laze2.dmg)**
   and open it.
2. Drag **2as w Laze2** onto the **Applications** shortcut sitting next to it.
   *(Never open the app inside the DMG — macOS blocks it there, and the fix
   can't be applied on a read-only volume.)*
3. Unblock it, either way works:
   - **Terminal:**

     ```bash
     xattr -dr com.apple.quarantine "/Applications/2as w Laze2.app"
     ```

   - **No Terminal:** open the app from Applications once — macOS blocks it,
     click **Done**. Then System Settings → **Privacy & Security** → scroll
     down → **Open Anyway** → confirm. This works on any Mac with no typing.
4. Open it from Applications.

Older versions live on the
[Releases page](https://github.com/ahmedabdelfattah7/2as-w-laz2/releases).

### 2. Accessibility permission

Auto-paste synthesises a ⌘V keystroke, which macOS only allows with the
Accessibility permission. The app asks on first launch; you can also grant it
under System Settings → Privacy & Security → **Accessibility**.

Without it, everything else still works — the item lands on your clipboard and
you press ⌘V yourself.

> Because the app is unsigned, macOS ties the permission to the exact binary.
> Installing a new version means granting it again.

## Use

| Key | |
|---|---|
| ⌘⇧V | Open the panel (press again to dismiss) |
| Type | Filter the history |
| ↑ / ↓ | Move the selection |
| Enter | Paste the selected item |
| Esc | Dismiss |

Clicking anywhere outside the panel dismisses it too.

**History is kept in memory only.** Nothing is ever written to disk, and the
history is gone when the app quits. That is deliberate — a clipboard manager
accumulates passwords and tokens, and the safest place to keep them is nowhere.
The list holds the 100 most recent items.

"Open at Login" is in the menu bar menu.

## Build from source

Requires Flutter (stable) and Xcode.

```bash
flutter build macos --release
```

The result is `build/macos/Build/Products/Release/2as w Laze2.app`, a universal
binary for both Apple Silicon and Intel.

### Working on it locally

Use the helper instead, which builds, signs, installs, and relaunches:

```bash
./tool/install.sh
```

Signing locally matters more than it looks. With Flutter's default **ad-hoc**
signature, the requirement macOS stores when you grant Accessibility is the
binary's hash:

```
designated => cdhash H"dd7f654f…"
```

So every rebuild silently invalidates the permission — the switch in System
Settings still shows as on, but the app is no longer trusted. Signing with any
real certificate replaces that with a certificate-based requirement containing
no hash, and the grant then survives every subsequent build.

The script picks the first Developer ID or Apple Development identity in your
keychain. Override it if you have several:

```bash
CLIPBOARD_SIGN_IDENTITY="Developer ID Application: …" ./tool/install.sh
```

If the permission ever does get into a bad state, clear it and start clean:

```bash
tccutil reset Accessibility com.ahmed.clipboard
```

## Releasing

`pubspec.yaml` holds the version. Tag it and CI does the rest:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

The workflow refuses to build if the tag and `pubspec.yaml` disagree.

## How it works

Roughly 300 lines of Dart and 300 of Swift, one dependency (`flutter_riverpod`),
no database.

- **Swift owns the system.** A 0.5 s timer compares `NSPasteboard.changeCount`
  — macOS has no clipboard-change notification, so this is the only mechanism
  that exists. The timer has a tolerance set so the kernel can coalesce its
  wakeup with others. A Carbon hot key handles ⌘⇧V, which is genuinely
  event-driven and needs no permission.
- **Dart owns the list and the UI.** Nothing periodic runs on the Dart side, so
  the isolate sleeps until you actually copy something.
- The window is only ever ordered in and out, never closed, so the Flutter
  engine stays warm and the panel opens instantly.
