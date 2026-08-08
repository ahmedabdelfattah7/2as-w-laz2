import 'package:copy_paste/clipboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The notifier installs a MethodChannel handler when it is created.
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
}
