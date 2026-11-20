/// Phone sign-in, independent of Firebase so screens are testable.
sealed class VerifyEvent {
  const VerifyEvent();
}

/// The SMS code was sent; confirm it with [verificationId].
class CodeSent extends VerifyEvent {
  const CodeSent(this.verificationId, this.resendToken);
  final String verificationId;
  final int? resendToken;
}

/// The device verified the code by itself (Android auto-retrieval) and signed in.
class AutoVerified extends VerifyEvent {
  const AutoVerified();
}

class VerifyFailed extends VerifyEvent {
  const VerifyFailed(this.code);
  final String code;
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);
  final String code;
  @override
  String toString() => 'AuthFailure($code)';
}

abstract class AuthRepository {
  String? get currentUid;
  Stream<String?> uidChanges();

  /// Starts (or, with [resendToken], restarts) SMS verification for [e164].
  Stream<VerifyEvent> verifyPhone(String e164, {int? resendToken});

  /// Signs in with the code. Throws [AuthFailure].
  Future<void> confirmCode(String verificationId, String smsCode);
  Future<void> signOut();
}
