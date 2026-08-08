import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clipboard.dart';

/// Toul kol saf sabet, w da beykhalli 7esab makan el selection tar7 basit
/// badal ma nes2al el layout 3an el arqam.
const _rowHeight = 34.0;

class Popup extends ConsumerStatefulWidget {
  const Popup({super.key});

  @override
  ConsumerState<Popup> createState() => _PopupState();
}

class _PopupState extends ConsumerState<Popup> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  late final FocusNode _focus = FocusNode(onKeyEvent: _onKey);

  int _selected = 0;
  List<String> _visible = const [];
  bool _panelVisible = false;

  @override
  void initState() {
    super.initState();
    onPanelVisibilityChanged = _setPanelVisible;
  }

  @override
  void dispose() {
    onPanelVisibilityChanged = null;
    _query.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Kol marra el panel yeftah beyebda2 min el awwil, w kol marra ye2fel
  /// bene-sheel kol 7aga gowah 3ashan mayefdalsh fih 7aga bete-animate.
  void _setPanelVisible(bool visible) {
    if (visible) {
      _query.clear();
      _selected = 0;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
    setState(() => _panelVisible = visible);
  }

  /// E7na masikeen el azrar 3ala el focus node bta3 el text field nafso,
  /// 3ashan nemsek el arrows 2abl ma el text field yakhodhom w ye7arrak
  /// el cursor beehom.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _accept();
    } else if (key == LogicalKeyboardKey.escape) {
      hidePanel();
    } else {
      // Ay zorar tani seebo yekammel 3ady lel text field.
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _move(int delta) {
    if (_visible.isEmpty) return;
    setState(() {
      _selected = (_selected + delta).clamp(0, _visible.length - 1);
    });
    _keepSelectionVisible();
  }

  void _keepSelectionVisible() {
    if (!_scroll.hasClients) return;
    final top = _selected * _rowHeight;
    final bottom = top + _rowHeight;
    final offset = _scroll.offset;
    final viewport = _scroll.position.viewportDimension;

    double? target;
    if (top < offset) {
      target = top;
    } else if (bottom > offset + viewport) {
      target = bottom - viewport;
    }
    // `jumpTo` mesh `animateTo`: el animation hatetlob frame kol tick min gher
    // fayda 7a2i2eya fe list soghayara zay di.
    if (target != null) {
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
    }
  }

  void _accept() {
    if (_selected < 0 || _selected >= _visible.length) return;
    pasteItem(_visible[_selected]);
  }

  @override
  Widget build(BuildContext context) {
    // Lama el panel yekoon ma5fi mafeesh 7aga betetbena2 khales. Mafeesh text
    // field ya3ni mafeesh cursor beye-blink, ya3ni mafeesh frames wala CPU —
    // w kaman el 7agat el gedida elly betetnasa5 mesh bete3mel rebuild lay 7aga.
    if (!_panelVisible) return const SizedBox.shrink();

    final history = ref.watch(historyProvider);
    final query = _query.text.trim().toLowerCase();
    _visible = query.isEmpty
        ? history
        : history.where((e) => e.toLowerCase().contains(query)).toList();
    if (_selected >= _visible.length) {
      _selected = _visible.isEmpty ? 0 : _visible.length - 1;
    }

    final theme = _Palette.of(context);

    return CupertinoPageScaffold(
      backgroundColor: theme.background,
      child: Column(
        children: [
          _searchField(theme),
          Container(height: 1, color: theme.divider),
          Expanded(
            child: _visible.isEmpty
                ? _emptyState(theme, history.isEmpty)
                : _list(theme),
          ),
        ],
      ),
    );
  }

  Widget _searchField(_Palette theme) {
    return CupertinoTextField(
      controller: _query,
      focusNode: _focus,
      autofocus: true,
      placeholder: 'Search clipboard',
      placeholderStyle: TextStyle(color: theme.secondary, fontSize: 14),
      style: TextStyle(color: theme.primary, fontSize: 14),
      cursorColor: theme.accent,
      // Cupertino be-default bey-fade el cursor fe w barra, w di animation
      // mostamerra ya3ni frame kol vsync tool ma el panel mafto7. El blink
      // el 3ady da mogarrad repaint marritin fel sanya.
      cursorOpacityAnimates: false,
      decoration: const BoxDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onChanged: (_) => setState(() => _selected = 0),
    );
  }

  Widget _emptyState(_Palette theme, bool historyEmpty) {
    return Center(
      child: Text(
        historyEmpty ? 'Nothing copied yet' : 'No matches',
        style: TextStyle(color: theme.secondary, fontSize: 13),
      ),
    );
  }

  Widget _list(_Palette theme) {
    return ListView.builder(
      controller: _scroll,
      itemExtent: _rowHeight,
      itemCount: _visible.length,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (context, i) {
        final isSelected = i == _selected;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            // El saf kollo yetdas 3aleh, mesh el kitaba bas. El test fe
            // widget_test.dart beyethabbet min el nokta di.
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _selected = i);
              _accept();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: isSelected ? theme.accent : null,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                // El enter w el masafat el keteera hay-basto el saf, fa
                // bene-lemhom fe satr wa7ed 3ashan el 3ard bas.
                _visible[i].replaceAll(RegExp(r'\s+'), ' ').trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? const Color(0xFFFFFFFF) : theme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shwayet alwan lel wad3 el fate7 w el ghame2. Mesh mestahel n3mel tabaqa
/// kamla lel theming 3ashan shasha wa7da bas.
class _Palette {
  const _Palette({
    required this.background,
    required this.primary,
    required this.secondary,
    required this.divider,
    required this.accent,
  });

  final Color background;
  final Color primary;
  final Color secondary;
  final Color divider;
  final Color accent;

  static _Palette of(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return dark
        ? const _Palette(
            background: Color(0xFF1E1E1E),
            primary: Color(0xFFEDEDED),
            secondary: Color(0xFF8A8A8A),
            divider: Color(0xFF343434),
            accent: Color(0xFF0A84FF),
          )
        : const _Palette(
            background: Color(0xFFF7F7F7),
            primary: Color(0xFF1A1A1A),
            secondary: Color(0xFF8A8A8A),
            divider: Color(0xFFDCDCDC),
            accent: Color(0xFF007AFF),
          );
  }
}
