/// A suggested place returned by a [PlacesSuggestionService] lookup.
class PlaceSuggestion {
  /// Creates a [PlaceSuggestion] with the given name,
  /// coordinates, and distance.
  const PlaceSuggestion({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  /// The display name of the place (e.g. "Walmart Supercenter").
  final String name;

  /// Latitude of the place centre.
  final double latitude;

  /// Longitude of the place centre.
  final double longitude;

  /// Straight-line distance in metres from the search origin.
  final double distanceMeters;
}

/// Abstraction over a place-search backend, injectable for testing.
// ignore: one_member_abstracts
abstract class PlacesSuggestionService {
  /// Returns the closest place whose name matches [keyword] within
  /// [radiusMeters] of ([lat], [lng]), or `null` if none is found.
  ///
  /// Implementations must never throw; they return `null` on any error.
  Future<PlaceSuggestion?> findNearbyPlace({
    required String keyword,
    required double lat,
    required double lng,
    double radiusMeters = 5000,
  });
}
