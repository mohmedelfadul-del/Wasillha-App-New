import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_driver/app/live.dart';
import 'package:wasilha_driver/features/documents/domain/document_repository.dart';
import 'package:wasilha_driver/features/documents/presentation/document_tile.dart';
import 'package:wasilha_driver/features/documents/presentation/documents_screen.dart';

import 'fakes.dart';

ReviewDocument doc(DocumentType type, ReviewStatus status, {String? reason}) => ReviewDocument.fromJson('drivers/d1/documents/${type.name}', {
      'type': type.name,
      'status': status.name,
      'reason': reason,
      'storagePath': 'drivers/d1/${type.name}/1.jpg',
      'driverId': 'd1',
      'submittedAt': 1,
      'decidedAt': status == ReviewStatus.pending ? null : 2,
    });

void main() {
  Future<Fakes> pumpTile(WidgetTester t, ReviewDocument? d, {String lang = 'en'}) async {
    final f = Fakes();
    await pumpHome(
      t,
      Scaffold(body: SingleChildScrollView(child: DocumentTile(uid: 'd1', type: DocumentType.driving_license, doc: d))),
      services: f.services(lang: lang),
    );
    return f;
  }

  testWidgets('not uploaded: badge and Upload action', (t) async {
    await pumpTile(t, null);
    expect(find.text('Not uploaded'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
  });

  testWidgets('pending: under review, no upload action', (t) async {
    await pumpTile(t, doc(DocumentType.driving_license, ReviewStatus.pending));
    expect(find.text('Under review'), findsOneWidget);
    expect(find.byIcon(Icons.upload_file), findsNothing);
  });

  testWidgets('approved: no upload action', (t) async {
    await pumpTile(t, doc(DocumentType.driving_license, ReviewStatus.approved));
    expect(find.text('Approved'), findsOneWidget);
    expect(find.byIcon(Icons.upload_file), findsNothing);
  });

  testWidgets('rejected: shows the reason, what to fix and a re-upload action', (t) async {
    await pumpTile(t, doc(DocumentType.driving_license, ReviewStatus.rejected, reason: 'Licence is expired'));
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Reason: Licence is expired'), findsOneWidget);
    expect(find.textContaining('What to fix'), findsOneWidget);
    expect(find.text('Upload again'), findsOneWidget);
  });

  testWidgets('rejected in Arabic shows the reason too', (t) async {
    await pumpTile(t, doc(DocumentType.driving_license, ReviewStatus.rejected, reason: 'الصورة غير واضحة'), lang: 'ar');
    expect(find.text('السبب: الصورة غير واضحة'), findsOneWidget);
    expect(find.text('ارفع صورة جديدة'), findsOneWidget);
  });

  testWidgets('changes requested: reason and re-upload', (t) async {
    await pumpTile(t, doc(DocumentType.driving_license, ReviewStatus.changesRequested, reason: 'Show both sides'));
    expect(find.text('Changes requested'), findsOneWidget);
    expect(find.text('Reason: Show both sides'), findsOneWidget);
    expect(find.text('Upload again'), findsOneWidget);
  });

  testWidgets('upload: gallery → Storage path → submitDocument; failure offers retry', (t) async {
    final f = Fakes();
    f.documents.failUploads = 1;
    await pumpHome(t, const Scaffold(body: SingleChildScrollView(child: DocumentTile(uid: 'd1', type: DocumentType.national_id, doc: null))), services: f.services(lang: 'en'));
    await t.tap(find.text('Upload'));
    await t.pumpAndSettle();
    await t.tap(find.text('Choose from gallery'));
    await t.pumpAndSettle();
    expect(find.textContaining('The upload didn’t finish.'), findsOneWidget);
    expect(f.documents.submits, isEmpty);
    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(f.documents.uploads.single, matches(RegExp(r'^drivers/d1/national_id/\d+\.jpg$')));
    expect(f.documents.submits.single.type, DocumentType.national_id);
    expect(f.documents.submits.single.vehicleId, isNull);
    expect(find.text('We received the document. It is now under review.'), findsOneWidget);
  });

  testWidgets('a file of 10 MB or more is refused before upload', (t) async {
    final f = Fakes();
    f.picker.bytes = Uint8List(maxUploadBytes);
    await pumpHome(t, const Scaffold(body: SingleChildScrollView(child: DocumentTile(uid: 'd1', type: DocumentType.national_id, doc: null))), services: f.services(lang: 'en'));
    await t.tap(find.text('Upload'));
    await t.pumpAndSettle();
    await t.tap(find.text('Take a photo'));
    await t.pumpAndSettle();
    expect(find.textContaining('larger than 10 MB'), findsOneWidget);
    expect(f.documents.uploads, isEmpty);
  });

  testWidgets('documents screen says submitting does not grant permission to work', (t) async {
    final f = Fakes();
    f.documents.driverDocs.add(Live({DocumentType.national_id: doc(DocumentType.national_id, ReviewStatus.pending)}));
    await pumpHome(t, const DocumentsScreen(uid: 'd1', status: DriverStatus.onboarding), services: f.services(lang: 'en'));
    await t.pump();
    expect(find.textContaining('Submitting does not let you work yet'), findsOneWidget);
    expect(find.text('National ID'), findsOneWidget);
    expect(find.text('Driving licence'), findsOneWidget);
  });
}
