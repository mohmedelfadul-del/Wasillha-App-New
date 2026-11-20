import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

class NewVehicle {
  const NewVehicle({required this.category, required this.make, required this.model, required this.color, required this.plate, required this.year});
  final Category category;
  final String make, model, color, plate;
  final int year;
}

abstract class VehicleRepository {
  /// vehicles where driverId == uid.
  Stream<Live<List<Vehicle>>> watchVehicles(String uid);

  /// Returns the new vehicle id.
  Future<String> add(NewVehicle v, {required IntentKey key});
}
