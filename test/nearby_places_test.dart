import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/services/navigation_service.dart';

/// Covers the parsing behind the "what's nearby" voice command.
///
/// The Places API returns results in its own relevance order and never tells
/// you how far away anything is. For someone who cannot see which way to
/// walk, "nearest first" is the whole point, so that sort is the part worth
/// pinning down.
void main() {
  Map<String, dynamic> place({
    required String name,
    required double lat,
    required double lng,
    List<String>? types,
    String? vicinity,
  }) {
    return {
      'name': name,
      'geometry': {
        'location': {'lat': lat, 'lng': lng},
      },
      if (types != null) 'types': types,
      if (vicinity != null) 'vicinity': vicinity,
    };
  }

  // Roughly 111 metres per 0.001 degrees of latitude.
  const originLat = 12.9716;
  const originLng = 77.5946;

  test('results come back nearest first, not in API order', () {
    final parsed = NavigationService.parseNearbyPlaces(
      {
        'results': [
          place(name: 'Far', lat: originLat + 0.003, lng: originLng),
          place(name: 'Near', lat: originLat + 0.0005, lng: originLng),
          place(name: 'Middle', lat: originLat + 0.0015, lng: originLng),
        ],
      },
      latitude: originLat,
      longitude: originLng,
    );

    expect(parsed.map((p) => p.name), ['Near', 'Middle', 'Far']);
  });

  test('distance is reported in metres from the user', () {
    final parsed = NavigationService.parseNearbyPlaces(
      {
        'results': [
          place(name: 'Up the road', lat: originLat + 0.001, lng: originLng),
        ],
      },
      latitude: originLat,
      longitude: originLng,
    );

    // 0.001 degrees of latitude is ~111m anywhere on earth.
    expect(parsed.single.distanceMeters, closeTo(111, 2));
  });

  test('structural Places types are not read out as the category', () {
    final parsed = NavigationService.parseNearbyPlaces(
      {
        'results': [
          place(
            name: 'Corner Shop',
            lat: originLat,
            lng: originLng,
            types: ['point_of_interest', 'establishment', 'pharmacy'],
          ),
        ],
      },
      latitude: originLat,
      longitude: originLng,
    );

    expect(parsed.single.category, 'pharmacy',
        reason: '"point of interest" tells a blind user nothing');
  });

  test('underscores in a type are not spoken literally', () {
    final parsed = NavigationService.parseNearbyPlaces(
      {
        'results': [
          place(
            name: 'Stop A',
            lat: originLat,
            lng: originLng,
            types: ['bus_station'],
          ),
        ],
      },
      latitude: originLat,
      longitude: originLng,
    );

    expect(parsed.single.category, 'bus station');
  });

  test('the list is capped so it can be held in the head', () {
    final parsed = NavigationService.parseNearbyPlaces(
      {
        'results': [
          for (var i = 0; i < 20; i++)
            place(name: 'Place $i', lat: originLat + (i * 0.0001), lng: originLng),
        ],
      },
      latitude: originLat,
      longitude: originLng,
      limit: 3,
    );

    expect(parsed, hasLength(3));
    expect(parsed.first.name, 'Place 0');
  });

  test('malformed entries are skipped rather than taking the list down', () {
    final parsed = NavigationService.parseNearbyPlaces(
      {
        'results': [
          {'name': 'No geometry'},
          {'geometry': {'location': {'lat': 1.0, 'lng': 2.0}}}, // no name
          'not a map',
          place(name: 'Good', lat: originLat, lng: originLng),
        ],
      },
      latitude: originLat,
      longitude: originLng,
    );

    expect(parsed.map((p) => p.name), ['Good']);
  });

  test('a response with no results list yields nothing', () {
    expect(
      NavigationService.parseNearbyPlaces(
        {'status': 'ZERO_RESULTS'},
        latitude: originLat,
        longitude: originLng,
      ),
      isEmpty,
    );
  });
}
