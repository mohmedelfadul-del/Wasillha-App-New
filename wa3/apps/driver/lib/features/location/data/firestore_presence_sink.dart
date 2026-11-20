import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/location_port.dart';

/// presence/{uid}: exactly the fields the rules allow; updatedAt is server time.
class FirestorePresenceSink implements PresenceSink {
  FirestorePresenceSink(this._db);
  final FirebaseFirestore _db;

  @override
  Future<void> write(String uid, Fix fix) => _db.collection('presence').doc(uid).set({
        'lat': fix.lat,
        'lng': fix.lng,
        'geohash': geohashEncode(fix.lat, fix.lng),
        'heading': ?fix.heading,
        'speed': ?fix.speed,
        'accuracy': ?fix.accuracy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
