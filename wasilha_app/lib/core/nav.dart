import 'package:flutter/material.dart';

/// Navigation helpers mirroring the prototype's `nav(id)` calls.
/// Route names are the screen ids from the prototype (see app.dart).
extension WNav on BuildContext {
  /// Push a screen on top of the current one.
  Future<T?> go<T>(String id, {Object? args}) => Navigator.of(this).pushNamed<T>(id, arguments: args);

  /// Replace the current screen.
  void swap(String id, {Object? args}) => Navigator.of(this).pushReplacementNamed(id, arguments: args);

  /// Clear the stack and start fresh at [id] (after login, finishing a trip...).
  void root(String id, {Object? args}) =>
      Navigator.of(this).pushNamedAndRemoveUntil(id, (_) => false, arguments: args);

  /// Switch bottom-nav tab: keep home underneath so back returns to it.
  void tab(String id) {
    final nav = Navigator.of(this);
    if (id == 'home') {
      nav.pushNamedAndRemoveUntil('home', (_) => false);
    } else {
      nav.pushNamedAndRemoveUntil(id, (r) => r.settings.name == 'home');
    }
  }

  void back() => Navigator.of(this).maybePop();
}
