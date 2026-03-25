import 'package:flutter/widgets.dart';
import '../service/translate_service.dart';
import '../widgets/translation_scope.dart';

extension StringTranslation on String {
  /// Sync translation — returns cached value instantly.
  /// No auto-rebuild. Use when BuildContext is not available.
  String get tr => TranslateService.instance.getSync(this);

  /// Sync translation WITH auto-rebuild.
  /// Call inside `build()` — widget re-renders when translation arrives.
  ///
  /// ```dart
  /// Text('Hello'.trOf(context))
  /// ```
  String trOf(BuildContext context) {
    TrData.watch(context);
    return TranslateService.instance.getSync(this);
  }

  /// For dynamic content (post body, comments, bio, etc.).
  /// Memory-only — never saved to SQLite. No auto-rebuild.
  String get trContent => TranslateService.instance.getContentSync(this);

  /// For dynamic content WITH auto-rebuild.
  /// Call inside `build()` — widget re-renders when translation arrives.
  ///
  /// ```dart
  /// Text(post.content?.trContentOf(context) ?? '')
  /// ```
  String trContentOf(BuildContext context) {
    TrData.watch(context);
    return TranslateService.instance.getContentSync(this);
  }
}
