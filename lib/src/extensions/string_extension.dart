import 'package:flutter/widgets.dart';
import '../service/translate_service.dart';
import '../widgets/translation_scope.dart';

extension StringTranslation on String {
  /// Sync translation — returns cached value instantly.
  /// No auto-rebuild. Use when BuildContext is not available.
  String get tr => TranslateService.instance.getSync(this);

  /// Like [tr] but preserves [dont] substrings from being translated.
  /// No auto-rebuild. Use when BuildContext is not available.
  ///
  /// ```dart
  /// 'Hello $name'.trWith(dont: [name])
  /// ```
  String trWith({required List<String> dont}) =>
      TranslateService.instance.getSyncWithDont(this, dont);

  /// Sync translation WITH auto-rebuild.
  /// Call inside `build()` — widget re-renders when translation arrives.
  ///
  /// Pass [dont] to preserve specific substrings (e.g. names, dates) from
  /// being translated.
  ///
  /// ```dart
  /// Text('Hello'.trOf(context))
  /// Text('Hello $name'.trOf(context, dont: [name]))
  /// ```
  String trOf(BuildContext context, {List<String>? dont}) {
    TrData.watch(context);
    if (dont == null || dont.isEmpty) {
      return TranslateService.instance.getSync(this);
    }
    return TranslateService.instance.getSyncWithDont(this, dont);
  }

  /// For dynamic content (post body, comments, bio, etc.).
  /// Memory-only — never saved to SQLite. No auto-rebuild.
  String get trContent => TranslateService.instance.getContentSync(this);

  /// Like [trContent] but preserves [dont] substrings from being translated.
  /// Memory-only — never saved to SQLite. No auto-rebuild.
  ///
  /// ```dart
  /// 'Posted by $name'.trContentWith(dont: [name])
  /// ```
  String trContentWith({required List<String> dont}) =>
      TranslateService.instance.getContentSyncWithDont(this, dont);

  /// For dynamic content WITH auto-rebuild.
  /// Call inside `build()` — widget re-renders when translation arrives.
  ///
  /// Pass [dont] to preserve specific substrings (e.g. names) from being translated.
  ///
  /// ```dart
  /// Text(post.content?.trContentOf(context) ?? '')
  /// Text('Posted by $name'.trContentOf(context, dont: [name]))
  /// ```
  String trContentOf(BuildContext context, {List<String>? dont}) {
    TrData.watch(context);
    if (dont == null || dont.isEmpty) {
      return TranslateService.instance.getContentSync(this);
    }
    return TranslateService.instance.getContentSyncWithDont(this, dont);
  }
}
