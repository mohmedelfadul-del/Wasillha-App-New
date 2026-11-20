import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:wa3_core/wa3_core.dart';

/// Maps Firestore / Storage / Auth exceptions to contract error codes, so every
/// screen explains reads the same way it explains commands.
ApiFailure toFailure(Object e) {
  if (e is ApiFailure) return e;
  if (e is FirebaseException) {
    final msg = e.message ?? e.code;
    return switch (e.code) {
      'permission-denied' || 'unauthorized' || 'unauthenticated' => ApiFailure('permission_denied', msg),
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' || 'retry-limit-exceeded' => ApiFailure('network', msg),
      'failed-precondition' when msg.toLowerCase().contains('index') => ApiFailure('index_missing', msg),
      'not-found' || 'object-not-found' => ApiFailure('not_found', msg),
      _ => ApiFailure(e.code, msg),
    };
  }
  if (e is TimeoutException) return const ApiFailure('network', 'Timed out');
  return ApiFailure('internal', e.toString());
}

extension FailureStreams<T> on Stream<T> {
  /// Re-emits errors as [ApiFailure].
  Stream<T> mapFailures() => transform(StreamTransformer.fromHandlers(
        handleError: (Object e, StackTrace st, EventSink<T> sink) => sink.addError(toFailure(e), st),
      ));
}

/// Runs [f], rethrowing any failure as [ApiFailure].
Future<T> guarded<T>(Future<T> Function() f) async {
  try {
    return await f();
  } catch (e) {
    throw toFailure(e);
  }
}
