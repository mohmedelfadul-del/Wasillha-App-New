import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../common/presentation/digits.dart';
import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';

enum SignInStage { phone, code }

/// Phone → SMS code → signed in. Errors are codes the screen explains.
class PhoneSignInController extends ChangeNotifier {
  PhoneSignInController(this._auth, {this.resendAfter = const Duration(seconds: 30), this.sendTimeout = const Duration(seconds: 90)});
  final AuthRepository _auth;
  final Duration resendAfter;
  final Duration sendTimeout;

  SignInStage stage = SignInStage.phone;
  String dialCode = defaultDialCode;
  String? e164;
  String? verificationId;
  int? _resendToken;
  DateTime? resendAvailableAt;
  bool autoVerifying = false;

  /// Local codes: invalid_phone_local, code_format, send_timeout. Otherwise Firebase Auth codes.
  String? error;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void clearError() {
    if (error == null) return;
    error = null;
    _notify();
  }

  /// Sends (or re-sends) the SMS. Completes when the code is sent, the device
  /// auto-verifies, or verification fails.
  Future<void> sendCode(String national, {required String lang}) async {
    final number = normalizePhone(dialCode, national);
    if (number == null) {
      error = 'invalid_phone_local';
      _notify();
      return;
    }
    e164 = number;
    await _send(lang: lang, resend: false);
  }

  Future<void> resend({required String lang}) => _send(lang: lang, resend: true);

  Future<void> _send({required String lang, required bool resend}) async {
    error = null;
    _notify();
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    try {
      await _auth.startVerification(e164!, lang: lang, resendToken: resend ? _resendToken : null, onEvent: (ev) {
        switch (ev) {
          case CodeSent(:final verificationId, :final resendToken):
            this.verificationId = verificationId;
            _resendToken = resendToken;
            stage = SignInStage.code;
            resendAvailableAt = DateTime.now().add(resendAfter);
          case AutoVerifying():
            autoVerifying = true;
          case VerificationFailed(:final code):
            autoVerifying = false;
            error = code;
        }
        _notify();
        finish();
      });
    } on AuthFailure catch (e) {
      error = e.code;
      _notify();
      finish();
    } catch (_) {
      error = 'unknown';
      _notify();
      finish();
    }
    await done.future.timeout(sendTimeout, onTimeout: () {
      error = 'send_timeout';
      _notify();
    });
  }

  Future<void> verify(String rawCode) async {
    final code = asciiDigits(rawCode).trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      error = 'code_format';
      _notify();
      return;
    }
    error = null;
    _notify();
    try {
      await _auth.confirmCode(verificationId!, code);
      // Success: the auth state stream moves the app on.
    } on AuthFailure catch (e) {
      error = e.code;
      _notify();
    }
  }

  void changeNumber() {
    stage = SignInStage.phone;
    verificationId = null;
    autoVerifying = false;
    error = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
