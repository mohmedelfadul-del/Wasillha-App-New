import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../../../app/services.dart';
import '../../../app/widgets/stale_notice.dart';
import 'account_status_card.dart';
import 'document_tile.dart';

/// The driver's personal KYC documents and what the account status means.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key, required this.uid, required this.status});
  final String uid;
  final DriverStatus status;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('وثائقي', 'My documents'))),
      body: DocumentsBody(stream: context.services.documents.watchDriverDocuments(uid), uid: uid, status: status),
    );
  }
}

class DocumentsBody extends StatefulWidget {
  const DocumentsBody({super.key, required this.stream, required this.uid, required this.status});
  final Stream<Live<Map<DocumentType, ReviewDocument>>> stream;
  final String uid;
  final DriverStatus status;
  @override
  State<DocumentsBody> createState() => _DocumentsBodyState();
}

class _DocumentsBodyState extends State<DocumentsBody> {
  late Stream<Live<Map<DocumentType, ReviewDocument>>> _stream = widget.stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Live<Map<DocumentType, ReviewDocument>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return WStateView.error(context, snap.error!, onRetry: () => setState(() => _stream = context.services.documents.watchDriverDocuments(widget.uid)));
        }
        if (!snap.hasData) return WStateView.loading();
        final docs = snap.data!.data;
        return ListView(
          padding: const EdgeInsets.all(WSpace.lg),
          children: [
            StaleNotice(fromCache: snap.data!.fromCache),
            AccountStatusCard(status: widget.status),
            const SizedBox(height: WSpace.lg),
            for (final type in driverDocumentTypes) ...[
              DocumentTile(uid: widget.uid, type: type, doc: docs[type]),
              const SizedBox(height: WSpace.md),
            ],
          ],
        );
      },
    );
  }
}
