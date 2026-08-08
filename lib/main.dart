import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clipboard.dart';
import 'popup.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // Create the history eagerly so the native channel handler is installed at
    // startup rather than on the first paint of the list — otherwise a copy
    // made in the first moments after launch would be missed.
    ref.read(historyProvider);
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: Popup(),
    );
  }
}
