import 'package:copy_paste/clipboard.dart';
import 'package:copy_paste/popup.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // El notifier bey-rakkeb handler lel MethodChannel awwil ma yetkhala2.
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  ClipboardHistory notifier() => container.read(historyProvider.notifier);
  List<String> history() => container.read(historyProvider);

  test('newest item comes first', () {
    notifier()
      ..add('one')
      ..add('two');
    expect(history(), ['two', 'one']);
  });

  test('re-copying moves an item to the top rather than duplicating it', () {
    notifier()
      ..add('one')
      ..add('two')
      ..add('one');
    expect(history(), ['one', 'two']);
  });

  test('blank text is ignored', () {
    notifier()
      ..add('   ')
      ..add('');
    expect(history(), isEmpty);
  });

  test('history is capped, dropping the oldest entries', () {
    final n = notifier();
    for (var i = 0; i < ClipboardHistory.maxItems + 20; i++) {
      n.add('item $i');
    }
    expect(history(), hasLength(ClipboardHistory.maxItems));
    expect(history().first, 'item ${ClipboardHistory.maxItems + 19}');
    expect(history(), isNot(contains('item 0')));
  });

  test('clear empties the history', () {
    notifier()
      ..add('one')
      ..clear();
    expect(history(), isEmpty);
  });

  /// El saf 3ardo kolo bel3ard bta3 el panel, w el kitaba gowah beteakhod
  /// gize2 soghayar min el shemal bas. Fa el dosa fel makan el fady 3ala el
  /// yemeen lazem teshtaghal zay el dosa 3ala el kitaba bel zabt.
  ///
  /// El test da mesh 3ashan 7aga kanet bayza — howa 3ashan tefdal shaghala.
  testWidgets('tapping the empty part of a row pastes it', (tester) async {
    const channel = MethodChannel('copy_paste/clipboard');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    container.read(historyProvider.notifier).add('hi');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CupertinoApp(home: Popup()),
      ),
    );

    // El panel beyeb2a fady lama yekoon ma5fi, fa lazem nefta7o el awwil.
    onPanelVisibilityChanged!(true);
    await tester.pumpAndSettle();

    final row = tester.getRect(
      find
          .ancestor(of: find.text('hi'), matching: find.byType(GestureDetector))
          .first,
    );
    // Bene-dous 3ala el 6araf el yemeen — makan mafihoosh kitaba khales.
    await tester.tapAt(Offset(row.right - 8, row.center.dy));
    await tester.pump();

    expect(
      calls.map((c) => c.method),
      contains('paste'),
      reason: 'a tap on blank row space must still paste',
    );
    expect(calls.firstWhere((c) => c.method == 'paste').arguments, 'hi');
  });
}
