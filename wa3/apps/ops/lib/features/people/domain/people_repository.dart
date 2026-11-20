import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

class RiderRecord {
  const RiderRecord({required this.uid, required this.name, required this.phone, this.lang, this.createdAt});
  final String uid;
  final String name;
  final String phone;
  final String? lang;
  final DateTime? createdAt;
}

abstract class PeopleRepository {
  /// Exact phone match (stored in E.164, e.g. +2499…).
  Future<List<RiderRecord>> ridersByPhone(String phone);
  Future<List<DriverProfile>> driversByPhone(String phone);
  Future<RiderRecord?> rider(String uid);
  Future<DriverProfile?> driver(String uid);
  Stream<Live<RiderRecord?>> watchRider(String uid);
  Stream<Live<DriverProfile?>> watchDriver(String uid);
  Stream<Live<List<ReviewDocument>>> driverDocuments(String uid);
  Stream<Live<List<Vehicle>>> vehicles(String driverId);
}

/// Phone-like input: optional +, then 7–15 digits (spaces and dashes ignored).
String? normalizePhone(String q) {
  final v = q.replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^\+?\d{7,15}$').hasMatch(v) ? v : null;
}
