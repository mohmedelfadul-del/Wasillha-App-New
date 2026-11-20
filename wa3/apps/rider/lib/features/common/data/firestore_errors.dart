import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:wa3_core/wa3_core.dart';

/// Maps Firestore failures onto the contract's error codes so screens can
/// explain them with `context.s.error(code)`.
Object mapFirestoreError(Object e) {
  if (e is ApiFailure) return e;
  if (e is FirebaseException) {
    return switch (e.code) {
      'permission-denied' || 'unauthenticated' => ApiFailure('permission_denied', e.message ?? e.code),
      'unavailable' || 'deadline-exceeded' => ApiFailure('network', e.message ?? e.code),
      'not-found' => ApiFailure('not_found', e.message ?? e.code),
      _ => ApiFailure(e.code, e.message ?? e.code),
    };
  }
  return e;
}

StreamTransformer<T, T> mapFirestoreErrors<T>() =>
    StreamTransformer<T, T>.fromHandlers(handleError: (e, st, sink) => sink.addError(mapFirestoreError(e), st));
