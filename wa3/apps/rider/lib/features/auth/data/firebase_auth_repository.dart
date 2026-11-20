import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  String? get phoneNumber => _auth.currentUser?.phoneNumber;

  @override
  Stream<String?> uidChanges() => _auth.authStateChanges().map((u) => u?.uid);

  @override
  Future<void> startVerification(String e164, {required String lang, int? resendToken, required void Function(PhoneEvent) onEvent}) async {
    await _auth.setLanguageCode(lang);
    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Android read the SMS (or instant verification): sign in directly.
        onEvent(const AutoVerifying());
        try {
          await _auth.signInWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          onEvent(VerificationFailed(e.code, e.message));
        }
      },
      verificationFailed: (e) => onEvent(VerificationFailed(e.code, e.message)),
      codeSent: (id, token) => onEvent(CodeSent(id, token)),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<void> confirmCode(String verificationId, String code) async {
    try {
      await _auth.signInWithCredential(PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code));
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.code, e.message);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
