/// Phone sign-in, abstracted from Firebase so screens are testable.
sealed class PhoneEvent {
  const PhoneEvent();
}

/// The SMS was sent; the user types the code.
class CodeSent extends PhoneEvent {
  const CodeSent(this.verificationId, this.resendToken);
  final String verificationId;
  final int? resendToken;
}

/// The device read the SMS itself (Android) and is signing in.
class AutoVerifying extends PhoneEvent {
  const AutoVerifying();
}

class VerificationFailed extends PhoneEvent {
  const VerificationFailed(this.code, [this.message]);
  final String code;
  final String? message;
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() => 'AuthFailure($code)';
}

abstract class AuthRepository {
  String? get uid;
  String? get phoneNumber;
  Stream<String?> uidChanges();

  /// Starts verification. Results arrive through [onEvent].
  Future<void> startVerification(String e164, {required String lang, int? resendToken, required void Function(PhoneEvent) onEvent});

  /// Signs in with the typed code; throws [AuthFailure].
  Future<void> confirmCode(String verificationId, String code);

  Future<void> signOut();
}
