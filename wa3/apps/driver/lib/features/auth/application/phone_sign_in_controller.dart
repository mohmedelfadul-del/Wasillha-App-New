import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';

enum SignInStep { phone, code }

class PhoneSignInController extends ChangeNotifier {
  PhoneSignInController(this.repo, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final AuthRepository repo;
  final DateTime Function() _clock;

  static const resendCooldown = Duration(seconds: 30);

  SignInStep step = SignInStep.phone;
  String? e164;
  String? errorCode;
  bool sending = false;
  DateTime? resendAt;
  String? _verificationId;
  int? _resendToken;
  StreamSubscription<VerifyEvent>? _sub;

  /// Sends the code. Returns false (with [errorCode]) on invalid input or failure.
  Future<bool> sendCode(String input, {bool resend = false}) async {
    final n = resend ? e164 : normalizePhone(input);
    if (n == null) {
      errorCode = 'invalid-phone-number';
      notifyListeners();
      return false;
    }
    e164 = n;
    errorCode = null;
    sending = true;
    notifyListeners();
    final done = Completer<bool>();
    await _sub?.cancel();
    _sub = repo.verifyPhone(n, resendToken: resend ? _resendToken : null).listen((ev) {
      switch (ev) {
        case CodeSent(:final verificationId, :final resendToken):
          _verificationId = verificationId;
          _resendToken = resendToken;
          step = SignInStep.code;
          resendAt = _clock().add(resendCooldown);
          if (!done.isCompleted) done.complete(true);
        case AutoVerified():
          if (!done.isCompleted) done.complete(true);
        case VerifyFailed(:final code):
          errorCode = code;
          if (!done.isCompleted) done.complete(false);
      }
      sending = false;
      notifyListeners();
    });
    return done.future;
  }

  /// Throws nothing: failures land in [errorCode].
  Future<void> confirm(String code) async {
    final id = _verificationId;
    if (id == null) return;
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) {
      errorCode = 'invalid-verification-code';
      notifyListeners();
      return;
    }
    errorCode = null;
    notifyListeners();
    try {
      await repo.confirmCode(id, code.trim());
    } on AuthFailure catch (e) {
      errorCode = e.code;
      notifyListeners();
    }
  }

  void changeNumber() {
    step = SignInStep.phone;
    errorCode = null;
    _verificationId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
