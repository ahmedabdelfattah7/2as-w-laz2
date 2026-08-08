# Clipboard

A small macOS clipboard history utility. Press **⌘⇧V** anywhere, type to filter,
press **Enter**, and the item is pasted straight into whatever app you were in.

It lives in the menu bar, has no Dock icon, and does nothing while you are not
using it.

## Install

Download the DMG from [Releases](../../releases) and drag **Clipboard.app** into
`/Applications`.

The app is **not signed or notarized**, so Gatekeeper will refuse to open it.
Clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine /Applications/Clipboard.app
```

The GUI alternative is System Settings → Privacy & Security → **Open Anyway**,
after the first launch attempt is blocked.

### Accessibility permission

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

The result is `build/macos/Build/Products/Release/Clipboard.app`, a universal
binary for both Apple Silicon and Intel.

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
