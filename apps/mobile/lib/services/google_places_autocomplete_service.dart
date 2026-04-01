import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:whileyoureout/services/places_autocomplete_service.dart';
import 'package:whileyoureout/services/places_suggestion_service.dart';

/// Calls the Google Places Autocomplete and Place Details REST APIs.
///
/// Returns empty / null results gracefully on any network error, timeout, or
/// missing API key. Never throws.
class GooglePlacesAutocompleteService implements PlacesAutocompleteService {
  /// Creates a [GooglePlacesAutocompleteService] with the given [apiKey].
  const GooglePlacesAutocompleteService({required this.apiKey});

  /// The Google Maps API key used to authenticate Places API requests.
  final String apiKey;

  static const String _autocompleteBaseUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  static const String _detailsBaseUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  @override
  Future<List<AutocompletePrediction>> getSuggestions(
    String input, {
    double? lat,
    double? lng,
  }) async {
    if (apiKey.isEmpty || input.trim().isEmpty) return [];

    final params = <String, String>{
      'input': input.trim(),
      'key': apiKey,
    };

    if (lat != null && lng != null) {
      params['location'] = '$lat,$lng';
      params['radius'] = '50000';
    }

    final uri =
        Uri.parse(_autocompleteBaseUrl).replace(queryParameters: params);

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = body['predictions'] as List<dynamic>? ?? [];

      return predictions.take(5).map((dynamic p) {
        final pred = p as Map<String, dynamic>;
        final structured =
            pred['structured_formatting'] as Map<String, dynamic>?;
        final mainText =
            structured?['main_text'] as String? ??
            pred['description'] as String? ??
            '';
        return AutocompletePrediction(
          placeId: pred['place_id'] as String? ?? '',
          description: pred['description'] as String? ?? '',
          mainText: mainText,
        );
      }).where((s) => s.placeId.isNotEmpty).toList();
    } catch (_) {
      // Network error, timeout, JSON parse error — degrade gracefully.
      return [];
    }
  }

  @override
  Future<PlaceSuggestion?> getPlaceDetails(String placeId) async {
    if (apiKey.isEmpty || placeId.isEmpty) return null;

    final uri = Uri.parse(_detailsBaseUrl).replace(queryParameters: {
      'place_id': placeId,
      'fields': 'geometry,name',
      'key': apiKey,
    },);

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final result = body['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final geometry = result['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final placeLat = (location['lat'] as num).toDouble();
      final placeLng = (location['lng'] as num).toDouble();
      final placeName =
          (result['name'] as String?)?.trim() ?? placeId;

      return PlaceSuggestion(
        name: placeName,
        latitude: placeLat,
        longitude: placeLng,
        distanceMeters: 0,
      );
    } catch (_) {
      // Network error, timeout, JSON parse error — degrade gracefully.
      return null;
    }
  }

  @override
  Future<String?> reverseGeocode(double lat, double lng) async {
    if (apiKey.isEmpty) return null;

    final uri =
        Uri.parse('https://maps.googleapis.com/maps/api/geocode/json')
            .replace(queryParameters: {
      'latlng': '$lat,$lng',
      'key': apiKey,
    },);

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String?;
      if (status != 'OK') return null;

      final results = body['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final formatted =
          (first['formatted_address'] as String?)?.trim();
      if (formatted == null || formatted.isEmpty) return null;

      // Use the first comma-delimited component as the short label,
      // e.g. "Walmart Supercenter" from
      //      "Walmart Supercenter, 1600 Main St, SF, CA 94103, USA"
      return formatted.split(',').first.trim();
    } catch (_) {
      // Network error, timeout, JSON parse error — degrade gracefully.
      return null;
    }
  }
}
