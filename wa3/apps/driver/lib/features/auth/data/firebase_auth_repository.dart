import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Stream<String?> uidChanges() => _auth.authStateChanges().map((u) => u?.uid);

  @override
  Stream<VerifyEvent> verifyPhone(String e164, {int? resendToken}) {
    final out = StreamController<VerifyEvent>();
    _auth
        .verifyPhoneNumber(
          phoneNumber: e164,
          forceResendingToken: resendToken,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (cred) async {
            try {
              await _auth.signInWithCredential(cred);
              out.add(const AutoVerified());
            } on FirebaseAuthException catch (e) {
              out.add(VerifyFailed(e.code));
            }
          },
          verificationFailed: (e) => out.add(VerifyFailed(e.code)),
          codeSent: (id, token) => out.add(CodeSent(id, token)),
          codeAutoRetrievalTimeout: (_) {},
        )
        .catchError((Object e) => out.add(VerifyFailed(e is FirebaseAuthException ? e.code : 'unknown')));
    return out.stream;
  }

  @override
  Future<void> confirmCode(String verificationId, String smsCode) async {
    try {
      await _auth.signInWithCredential(PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode));
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.code);
    } catch (_) {
      throw const AuthFailure('network-request-failed');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
