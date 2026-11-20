import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wa3_core/wa3_core.dart';

import '../features/audit/data/firestore_audit_repository.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/cases/data/firestore_cases_repository.dart';
import '../features/cockpit/data/firestore_cockpit_repository.dart';
import '../features/finance/data/firestore_finance_repository.dart';
import '../features/kyc/data/firestore_kyc_repository.dart';
import '../features/people/data/firestore_people_repository.dart';
import '../features/pricing/data/firestore_pricing_repository.dart';
import '../features/trips/data/firestore_trips_repository.dart';
import 'services.dart';

OpsServices firebaseServices() {
  final db = FirebaseFirestore.instance;
  final api = WasilhaApi();
  return OpsServices(
    auth: FirebaseAuthRepository(),
    cockpit: FirestoreCockpitRepository(db),
    kyc: FirestoreKycRepository(db, FirebaseStorage.instance, api),
    trips: FirestoreTripsRepository(db, api),
    cases: FirestoreCasesRepository(db, api),
    people: FirestorePeopleRepository(db),
    pricing: FirestorePricingRepository(db, api),
    finance: FirestoreFinanceRepository(db, api),
    audit: FirestoreAuditRepository(db),
  );
}
