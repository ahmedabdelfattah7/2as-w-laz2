import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one channel shared with the macOS side.
const _channel = MethodChannel('copy_paste/clipboard');

/// Invoked when the native side shows or hides the panel.
///
/// A plain callback rather than a provider: exactly one widget ever listens,
/// and it is a transient signal rather than state anyone needs to read.
///
/// This matters for more than resetting the search box. While the panel is
/// hidden the UI is torn down entirely, because a focused text field keeps its
/// cursor blinking, and a blinking cursor keeps Flutter scheduling frames for a
/// window nobody can see.
void Function(bool visible)? onPanelVisibilityChanged;

/// Puts [text] on the pasteboard, hides the panel, and pastes it into whatever
/// app was frontmost before the panel opened.
Future<void> pasteItem(String text) =>
    _channel.invokeMethod<void>('paste', text);

/// Hides the panel without pasting.
Future<void> hidePanel() => _channel.invokeMethod<void>('hide');

/// The clipboard history: newest first, de-duplicated, capped.
///
/// This is the only shared state in the app, which is why it is the only
/// provider. Search text and selection live in the widget that owns them.
class ClipboardHistory extends Notifier<List<String>> {
  static const maxItems = 100;

  @override
  List<String> build() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCopy':
          add(call.arguments as String);
        case 'onShow':
          onPanelVisibilityChanged?.call(true);
        case 'onHide':
          onPanelVisibilityChanged?.call(false);
        case 'onClear':
          clear();
      }
      return null;
    });
    return const [];
  }

  void add(String text) {
    if (text.trim().isEmpty) return;
    // Re-copying something already in the list moves it to the top rather than
    // creating a second entry.
    final next = <String>[text, ...state.where((e) => e != text)];
    state = next.length > maxItems ? next.sublist(0, maxItems) : next;
  }

  void clear() => state = const [];
}

final historyProvider =
    NotifierProvider<ClipboardHistory, List<String>>(ClipboardHistory.new);
