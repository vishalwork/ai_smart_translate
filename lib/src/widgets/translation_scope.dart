import 'dart:async';
import 'package:flutter/widgets.dart';
import '../service/translate_service.dart';

/// InheritedWidget that holds a tick counter.
/// Every widget that calls `.trOf(context)` depends on this.
/// When tick increments → all dependent widgets auto-rebuild.
class TrData extends InheritedWidget {
  const TrData({super.key, required this.tick, required super.child});

  final int tick;

  /// Call this inside build() to register a rebuild dependency.
  static void watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TrData>();

  @override
  bool updateShouldNotify(TrData old) => tick != old.tick;
}

/// Wrap your app (or any screen) with [TranslationScope].
///
/// - Language change → all `.trOf(context)` widgets rebuild instantly.
/// - New translations arrive → all `.trOf(context)` widgets rebuild.
///
/// ```dart
/// // main.dart
/// runApp(TranslationScope(child: MyApp()));
///
/// // Per-screen (optional, for finer control)
/// TranslationScope(child: HomeScreen())
/// ```
class TranslationScope extends StatefulWidget {
  const TranslationScope({super.key, required this.child});
  final Widget child;

  @override
  State<TranslationScope> createState() => _TranslationScopeState();
}

class _TranslationScopeState extends State<TranslationScope> {
  int _tick = 0;
  late final StreamSubscription<String> _langSub;
  late final StreamSubscription<void> _updateSub;

  @override
  void initState() {
    super.initState();
    final svc = TranslateService.instance;

    // Language changed → increment tick
    _langSub = svc.languageStream.listen((_) {
      if (mounted) setState(() => _tick++);
    });

    // New translations cached → increment tick
    _updateSub = svc.onUpdate.listen((_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _langSub.cancel();
    _updateSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrData(tick: _tick, child: widget.child);
  }
}
