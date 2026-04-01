import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:whileyoureout/services/places_suggestion_service.dart';

/// Calls the Google Places Nearby Search REST API (legacy v1).
///
/// Returns null on any network error, timeout, or if the API key is empty.
/// Never throws.
class GooglePlacesSuggestionService implements PlacesSuggestionService {
  /// Creates a [GooglePlacesSuggestionService] with the given [apiKey].
  const GooglePlacesSuggestionService({required this.apiKey});

  /// The Google Maps API key used to authenticate Places API requests.
  final String apiKey;

  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  @override
  Future<PlaceSuggestion?> findNearbyPlace({
    required String keyword,
    required double lat,
    required double lng,
    double radiusMeters = 5000,
  }) async {
    if (apiKey.isEmpty || keyword.trim().isEmpty) return null;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'location': '$lat,$lng',
      'radius': radiusMeters.toInt().toString(),
      'keyword': keyword.trim(),
      'key': apiKey,
    },);

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final placeLat = (location['lat'] as num).toDouble();
      final placeLng = (location['lng'] as num).toDouble();
      final placeName =
          (first['name'] as String?)?.trim() ?? keyword.trim();

      return PlaceSuggestion(
        name: placeName,
        latitude: placeLat,
        longitude: placeLng,
        distanceMeters: _haversineMeters(lat, lng, placeLat, placeLng),
      );
    } catch (_) {
      // Network error, timeout, JSON parse error — degrade gracefully.
      return null;
    }
  }

  /// Haversine formula: straight-line distance in metres between two points.
  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
