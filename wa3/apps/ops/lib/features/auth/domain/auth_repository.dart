import 'package:wa3_core/wa3_core.dart';

/// The signed-in staff member as the ID token describes them.
class StaffSession {
  const StaffSession({
    required this.uid,
    this.email,
    required this.staff,
    this.role,
    required this.secondFactor,
    required this.hasEnrolledTotp,
  });
  final String uid;
  final String? email;

  /// Custom claim `staff == true`.
  final bool staff;

  /// Custom claim `role`, null when missing or unknown.
  final StaffRole? role;

  /// The token was issued after a TOTP second factor (`firebase.sign_in_second_factor == 'totp'`).
  final bool secondFactor;
  final bool hasEnrolledTotp;

  bool get authorized => staff && role != null;

  static StaffRole? parseRole(Object? v) {
    for (final r in StaffRole.values) {
      if (r.name == v) return r;
    }
    return null;
  }
}

/// What the gate shows for a session.
enum GateState { signedOut, accessDenied, enrollTotp, reauthWithTotp, ready }

GateState gateFor(StaffSession? s, {bool mfaOptional = false}) {
  if (s == null) return GateState.signedOut;
  if (!s.authorized) return GateState.accessDenied;
  if (s.secondFactor || mfaOptional) return GateState.ready;
  return s.hasEnrolledTotp ? GateState.reauthWithTotp : GateState.enrollTotp;
}

sealed class SignInOutcome {
  const SignInOutcome();
}

class SignedIn extends SignInOutcome {
  const SignedIn();
}

/// Password accepted; a TOTP code is needed to finish.
class NeedsTotp extends SignInOutcome {
  const NeedsTotp(this.challenge);
  final MfaChallenge challenge;
}

class MfaChallenge {
  const MfaChallenge({required this.handle, this.factorName});

  /// Opaque platform object (the resolver); only the data layer reads it.
  final Object handle;
  final String? factorName;
}

class TotpEnrollment {
  const TotpEnrollment({required this.secretKey, required this.otpauthUri, required this.handle, this.codeLength, this.intervalSeconds, this.deadline});
  final String secretKey;
  final String otpauthUri;
  final Object handle;
  final int? codeLength;
  final int? intervalSeconds;
  final DateTime? deadline;
}

/// Auth operations. Failures are [ApiFailure] with code `auth/<firebase code>`.
abstract class AuthRepository {
  /// Emits on every sign-in, sign-out and ID-token refresh (claims included).
  Stream<StaffSession?> sessions();
  Future<SignInOutcome> signIn(String email, String password);
  Future<void> resolveTotp(MfaChallenge challenge, String code);
  Future<TotpEnrollment> startTotpEnrollment();
  Future<void> completeTotpEnrollment(TotpEnrollment enrollment, String code);

  /// Forces an ID-token refresh so new claims are read.
  Future<void> refresh();
  Future<void> signOut();
}

/// Six-digit authenticator code check (client-side shape check only).
bool isTotpCode(String v) => RegExp(r'^\d{6}$').hasMatch(v.trim());
