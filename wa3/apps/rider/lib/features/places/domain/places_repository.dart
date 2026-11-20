import 'package:wa3_core/wa3_core.dart';

class PlaceSuggestion {
  const PlaceSuggestion({required this.label, required this.address, required this.point});
  final String label;
  final String address;
  final GeoPoint point;
  Place toPlace() => Place(point: point, label: label.isNotEmpty ? label : address);
}

/// Server-proxied places (`placesSearch`, `placeLabel`); no client keys.
abstract class PlacesRepository {
  Future<List<PlaceSuggestion>> search(String query, {required GeoPoint near, required String lang});
  Future<String> label(GeoPoint point, {required String lang});
}
