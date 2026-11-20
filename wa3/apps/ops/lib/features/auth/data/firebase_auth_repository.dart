import 'package:firebase_auth/firebase_auth.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  @override
  Stream<StaffSession?> sessions() => _auth.idTokenChanges().asyncMap((u) async {
        if (u == null) return null;
        final token = await u.getIdTokenResult();
        final claims = token.claims ?? const {};
        List<MultiFactorInfo> factors = const [];
        try {
          factors = await u.multiFactor.getEnrolledFactors();
        } catch (_) {}
        return StaffSession(
          uid: u.uid,
          email: u.email,
          staff: claims['staff'] == true,
          role: StaffSession.parseRole(claims['role']),
          secondFactor: token.signInSecondFactor == 'totp',
          hasEnrolledTotp: factors.any((f) => f.factorId == 'totp'),
        );
      });

  @override
  Future<SignInOutcome> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return const SignedIn();
    } on FirebaseAuthMultiFactorException catch (e) {
      final hint = e.resolver.hints.where((h) => h.factorId == 'totp').firstOrNull;
      if (hint == null) throw const ApiFailure('auth/no-totp-factor', 'This account has no authenticator app enrolled');
      return NeedsTotp(MfaChallenge(handle: (e.resolver, hint.uid), factorName: hint.displayName));
    } on FirebaseAuthException catch (e) {
      throw ApiFailure('auth/${e.code}', e.message ?? e.code);
    }
  }

  @override
  Future<void> resolveTotp(MfaChallenge challenge, String code) async {
    final (resolver, enrollmentId) = challenge.handle as (MultiFactorResolver, String);
    try {
      final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(enrollmentId, code.trim());
      await resolver.resolveSignIn(assertion);
    } on FirebaseAuthException catch (e) {
      throw ApiFailure('auth/${e.code}', e.message ?? e.code);
    }
  }

  @override
  Future<TotpEnrollment> startTotpEnrollment() async {
    final u = _auth.currentUser;
    if (u == null) throw const ApiFailure('auth/no-current-user', 'Sign in first');
    try {
      final session = await u.multiFactor.getSession();
      final secret = await TotpMultiFactorGenerator.generateSecret(session);
      final uri = await secret.generateQrCodeUrl(accountName: u.email ?? u.uid, issuer: 'Wasilha Ops');
      return TotpEnrollment(
        secretKey: secret.secretKey,
        otpauthUri: uri,
        handle: secret,
        codeLength: secret.codeLength,
        intervalSeconds: secret.codeIntervalSeconds,
        deadline: secret.enrollmentCompletionDeadline,
      );
    } on FirebaseAuthException catch (e) {
      throw ApiFailure('auth/${e.code}', e.message ?? e.code);
    }
  }

  @override
  Future<void> completeTotpEnrollment(TotpEnrollment enrollment, String code) async {
    final u = _auth.currentUser;
    if (u == null) throw const ApiFailure('auth/no-current-user', 'Sign in first');
    try {
      final assertion = await TotpMultiFactorGenerator.getAssertionForEnrollment(enrollment.handle as TotpSecret, code.trim());
      await u.multiFactor.enroll(assertion, displayName: 'Authenticator app');
      await u.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      throw ApiFailure('auth/${e.code}', e.message ?? e.code);
    }
  }

  @override
  Future<void> refresh() async => _auth.currentUser?.getIdToken(true);

  @override
  Future<void> signOut() => _auth.signOut();
}
