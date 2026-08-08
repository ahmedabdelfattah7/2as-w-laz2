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
    // Bene3mel el history min awwil lah7za 3ashan el handler bta3 el channel
    // yetrakkeb ma3a bedayet el app, mesh awwil ma el list tetrasem — 8er keda
    // ay nas5 ye7sal fe awwil lawa7i min el tashgheel kan hayedee3.
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
