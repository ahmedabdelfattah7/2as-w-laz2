import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El channel el wa7eed elly beyrabetna bel gize2 el macOS.
const _channel = MethodChannel('copy_paste/clipboard');

/// Betetnadi lama el nas el macOS yeftah aw ye2fel el panel.
///
/// Callback 3adi mesh provider: fih widget wa7ed bas beyesma3ha, w di eshara
/// bete3addi mesh 7ala 7ad me7tag ye2raha.
///
/// W di mohimma le akhtar min mogarrad tafdeyet 5anet el ba7s: tool ma el
/// panel ma5fi e7na bene-sheel el UI kolaha, 3ashan el text field lama yekoon
/// masek el focus beyfdal 3ammal ye-blink, w el blink da beykhalli Flutter
/// yetlob frames le window ma7addesh shayefha.
void Function(bool visible)? onPanelVisibilityChanged;

/// Bet7ott [text] 3ala el clipboard, te2fel el panel, w te3mel paste fel app
/// elly kanet 2oddam 2abl ma el panel yeftah.
Future<void> pasteItem(String text) =>
    _channel.invokeMethod<void>('paste', text);

/// Bet2fel el panel min gher paste.
Future<void> hidePanel() => _channel.invokeMethod<void>('hide');

/// Tarikh el clipboard: el gedeed fel awwil, min gher tekrar, w be7add a2sa.
///
/// Di el 7ala el moshtaraka el wa7eda fel app, 3ashan keda heya el provider
/// el wa7eed. El ba7s w el ekhteyar 3aysheen gowa el widget elly bey-stakhdemhom.
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
    // Law nasakht 7aga mawgooda 2abl keda, betetla3 fo2 badal ma yeb2a fih
    // nos5tin minha fel list.
    final next = <String>[text, ...state.where((e) => e != text)];
    state = next.length > maxItems ? next.sublist(0, maxItems) : next;
  }

  void clear() => state = const [];
}

final historyProvider =
    NotifierProvider<ClipboardHistory, List<String>>(ClipboardHistory.new);
