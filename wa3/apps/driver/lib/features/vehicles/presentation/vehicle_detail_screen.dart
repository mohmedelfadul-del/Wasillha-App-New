import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../../../app/services.dart';
import '../../../app/widgets/stale_notice.dart';
import '../../documents/presentation/document_tile.dart';
import 'vehicles_screen.dart';

/// A vehicle's details and its three documents, each with its review status.
class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({super.key, required this.uid, required this.vehicle});
  final String uid;
  final Vehicle vehicle;
  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Stream<Live<Map<DocumentType, ReviewDocument>>> _docs = context.services.documents.watchVehicleDocuments(widget.vehicle.id);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final v = widget.vehicle;
    return Scaffold(
      appBar: AppBar(title: Text('${v.make} ${v.model}')),
      body: StreamBuilder<Live<Map<DocumentType, ReviewDocument>>>(
        stream: _docs,
        builder: (context, snap) {
          if (snap.hasError) {
            return WStateView.error(context, snap.error!, onRetry: () => setState(() => _docs = context.services.documents.watchVehicleDocuments(v.id)));
          }
          if (!snap.hasData) return WStateView.loading();
          final docs = snap.data!.data;
          return ListView(padding: const EdgeInsets.all(WSpace.lg), children: [
            StaleNotice(fromCache: snap.data!.fromCache),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(WSpace.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${v.color} ${v.make} ${v.model}', style: Theme.of(context).textTheme.titleMedium),
                  Text('${s.category(v.category)} · ${ltr(v.plate)} · ${ltr('${v.year}')}'),
                  const SizedBox(height: WSpace.sm),
                  StatusBadge(tone: vehicleTone(v.status), label: vehicleStatusLabel(s, v.status)),
                  const SizedBox(height: WSpace.sm),
                  Text(s.t('لا يمكنك العمل بهذه المركبة حتى نعتمد وثائقها الثلاث.', 'You can’t drive this vehicle for work until all three documents are approved.')),
                ]),
              ),
            ),
            const SizedBox(height: WSpace.lg),
            for (final type in vehicleDocumentTypes) ...[
              DocumentTile(uid: widget.uid, type: type, doc: docs[type], vehicleId: v.id),
              const SizedBox(height: WSpace.md),
            ],
          ]);
        },
      ),
    );
  }
}
