import 'package:whileyoureout/services/places_suggestion_service.dart';

/// A single autocomplete prediction returned by the Places Autocomplete API.
class AutocompletePrediction {
  /// Creates an [AutocompletePrediction].
  const AutocompletePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
  });

  /// The unique Google Place ID used to fetch detailed place information.
  final String placeId;

  /// Full human-readable description, e.g.
  /// "Walmart Supercenter, Market Street, San Francisco, CA, USA".
  final String description;

  /// Primary display name, e.g. "Walmart Supercenter".
  final String mainText;
}

/// Abstraction over the Google Places Autocomplete + Place Details backends,
/// injectable for testing.
abstract class PlacesAutocompleteService {
  /// Returns up to 5 autocomplete predictions for the given [input] string.
  ///
  /// When [lat] and [lng] are provided the results are biased towards that
  /// geographic location.
  ///
  /// Returns an empty list when [input] is blank, the API key is missing, or
  /// any network / parse error occurs. Never throws.
  Future<List<AutocompletePrediction>> getSuggestions(
    String input, {
    double? lat,
    double? lng,
  });

  /// Fetches the name and coordinates for the place identified by [placeId].
  ///
  /// Returns a [PlaceSuggestion] on success, or `null` if the place could not
  /// be found or any network / parse error occurs. Never throws.
  Future<PlaceSuggestion?> getPlaceDetails(String placeId);

  /// Reverse-geocodes ([lat], [lng]) to a short human-readable place label.
  ///
  /// Returns the primary component of the formatted address (e.g.
  /// `"Walmart Supercenter"` or `"1600 Amphitheatre Pkwy"`), or `null` when
  /// the API key is missing, the coordinates resolve to nothing useful, or any
  /// network / parse error occurs. Never throws.
  Future<String?> reverseGeocode(double lat, double lng);
}
