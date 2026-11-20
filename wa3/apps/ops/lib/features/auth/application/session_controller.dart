import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/auth_repository.dart';

/// Holds the current staff session from the auth stream.
class SessionController extends ChangeNotifier {
  SessionController(this._repo) {
    _sub = _repo.sessions().listen((s) {
      _session = s;
      _loaded = true;
      notifyListeners();
    }, onError: (Object e) {
      _loaded = true;
      _error = e;
      notifyListeners();
    });
  }

  final AuthRepository _repo;
  late final StreamSubscription<StaffSession?> _sub;
  StaffSession? _session;
  bool _loaded = false;
  Object? _error;

  AuthRepository get repo => _repo;
  StaffSession? get session => _session;
  bool get loaded => _loaded;
  Object? get error => _error;

  Future<void> signOut() => _repo.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// The ready, authorized session for the console below the gate.
class SessionScope extends InheritedWidget {
  const SessionScope({super.key, required this.session, required this.onSignOut, required super.child});
  final StaffSession session;
  final Future<void> Function() onSignOut;

  static SessionScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SessionScope>()!;

  @override
  bool updateShouldNotify(SessionScope old) =>
      old.session.uid != session.uid || old.session.role != session.role || old.session.secondFactor != session.secondFactor;
}

extension SessionX on BuildContext {
  StaffSession get session => SessionScope.of(this).session;
  StaffRole? get role => session.role;
  String get myUid => session.uid;
}
