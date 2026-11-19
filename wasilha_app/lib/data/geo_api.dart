import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Google Places (New) text search + Routes API, enabled with
///   flutter run --dart-define=GOOGLE_API_KEY=your_key
/// Restrict the key to these APIs and to your app's package / bundle id.
/// Without a key the app uses the built-in Khartoum catalog and straight lines.
const kGoogleApiKey = String.fromEnvironment('GOOGLE_API_KEY');

class GeoApi {
  GeoApi._();

  static bool get enabled => kGoogleApiKey.isNotEmpty;

  // Greater Khartoum, used to bias search results.
  static const _biasLat = 15.5800, _biasLng = 32.5400, _biasRadiusM = 40000.0;

  /// Address / place search. Returns [] on any failure so callers can fall back.
  static Future<List<Place>> searchPlaces(String query, {String lang = 'en'}) async {
    final q = query.trim();
    if (!enabled || q.length < 2) return const [];
    try {
      final res = await http
          .post(
            Uri.parse('https://places.googleapis.com/v1/places:searchText'),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': kGoogleApiKey,
              'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location',
            },
            body: jsonEncode({
              'textQuery': q,
              'languageCode': lang,
              'regionCode': 'SD',
              'maxResultCount': 8,
              'locationBias': {
                'circle': {
                  'center': {'latitude': _biasLat, 'longitude': _biasLng},
                  'radius': _biasRadiusM,
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final places = (jsonDecode(res.body)['places'] as List?) ?? const [];
      return [
        for (final p in places.cast<Map<String, dynamic>>())
          if (p['location'] != null)
            Place(
              id: 'g:${p['id']}',
              name: (p['displayName']?['text'] ?? '') as String,
              nameAr: lang == 'ar' ? (p['displayName']?['text'] ?? '') as String : '',
              area: _shortAddress((p['formattedAddress'] ?? '') as String),
              lat: (p['location']['latitude'] as num).toDouble(),
              lng: (p['location']['longitude'] as num).toDouble(),
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static String _shortAddress(String a) {
    final parts = a.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return parts.length <= 2 ? a : parts.sublist(0, 2).join(', ');
  }

  static final _routeCache = <String, List<(double, double)>>{};

  /// Road-following path between two places (driving). Null on failure.
  static Future<List<(double, double)>?> route(Place from, Place to) async {
    if (!enabled) return null;
    final key = '${from.lat},${from.lng}>${to.lat},${to.lng}';
    final cached = _routeCache[key];
    if (cached != null) return cached;
    try {
      final res = await http
          .post(
            Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': kGoogleApiKey,
              'X-Goog-FieldMask': 'routes.polyline.encodedPolyline,routes.duration,routes.distanceMeters',
            },
            body: jsonEncode({
              'origin': {'location': {'latLng': {'latitude': from.lat, 'longitude': from.lng}}},
              'destination': {'location': {'latLng': {'latitude': to.lat, 'longitude': to.lng}}},
              'travelMode': 'DRIVE',
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final routes = (jsonDecode(res.body)['routes'] as List?) ?? const [];
      if (routes.isEmpty) return null;
      final enc = routes.first['polyline']?['encodedPolyline'] as String?;
      if (enc == null) return null;
      return _routeCache[key] = decodePolyline(enc);
    } catch (_) {
      return null;
    }
  }

  /// Google encoded polyline → list of (lat, lng).
  static List<(double, double)> decodePolyline(String s) {
    final out = <(double, double)>[];
    var i = 0, lat = 0, lng = 0;
    int next() {
      var shift = 0, result = 0, b = 0;
      do {
        b = s.codeUnitAt(i++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    }

    while (i < s.length) {
      lat += next();
      lng += next();
      out.add((lat / 1e5, lng / 1e5));
    }
    return out;
  }
}
