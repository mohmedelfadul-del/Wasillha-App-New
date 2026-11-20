import 'package:wa3_core/wa3_core.dart';

import '../domain/places_repository.dart';

class ApiPlacesRepository implements PlacesRepository {
  ApiPlacesRepository(this._api);
  final WasilhaApi _api;

  @override
  Future<List<PlaceSuggestion>> search(String query, {required GeoPoint near, required String lang}) async {
    final rows = await _api.placesSearch(query: query, lat: near.lat, lng: near.lng, lang: lang);
    return [
      for (final r in rows)
        PlaceSuggestion(
          label: (r['label'] ?? '').toString(),
          address: (r['address'] ?? '').toString(),
          point: GeoPoint(((r['lat'] as num?) ?? 0).toDouble(), ((r['lng'] as num?) ?? 0).toDouble()),
        ),
    ];
  }

  @override
  Future<String> label(GeoPoint point, {required String lang}) => _api.placeLabel(lat: point.lat, lng: point.lng, lang: lang);
}
