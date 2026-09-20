import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Navigation service using Google Maps Directions API
/// Converts route steps into voice-friendly instructions
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  String? _apiKey;
  List<NavigationStep> _steps = [];
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  List<LatLng> _polylinePoints = [];
  LatLng? _destinationLatLng;

  // Mock mode for testing without API
  bool useMock = false;

  /// Initialize with API key
  void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  /// Get directions from origin to destination
  Future<NavigationResult> getDirections({
    required double originLat,
    required double originLng,
    required String destination,
    String mode = 'walking', // walking, driving, bicycling, transit
  }) async {
    if (useMock) {
      return _getMockDirections(originLat: originLat, originLng: originLng);
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      return NavigationResult(
        success: false,
        error: 'Google Maps API key not configured',
      );
    }

    try {
      final origin = '$originLat,$originLng';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$origin'
        '&destination=${Uri.encodeComponent(destination)}'
        '&mode=$mode'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return NavigationResult(
          success: false,
          error: 'API request failed: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      if (data['status'] != 'OK') {
        return NavigationResult(
          success: false,
          error: 'Directions not found: ${data['status']}',
        );
      }

      // Parse route steps
      _steps = [];
      final legs = data['routes'][0]['legs'] as List;
      for (var leg in legs) {
        final steps = leg['steps'] as List;
        for (var step in steps) {
          _steps.add(NavigationStep(
            instruction: _cleanHtmlTags(step['html_instructions']),
            distance: step['distance']['text'],
            distanceMeters: step['distance']['value'],
            duration: step['duration']['text'],
            maneuver: step['maneuver'] ?? '',
            startLat: step['start_location']['lat'],
            startLng: step['start_location']['lng'],
            endLat: step['end_location']['lat'],
            endLng: step['end_location']['lng'],
          ));
        }
      }

      _currentStepIndex = 0;
      _isNavigating = true;

      // Extract polyline
      if (data['routes'].isNotEmpty) {
        final overviewPolyline = data['routes'][0]['overview_polyline']['points'];
        _polylinePoints = _decodePolyline(overviewPolyline);
        
        final endLocation = data['routes'][0]['legs'][0]['end_location'];
        _destinationLatLng = LatLng(endLocation['lat'], endLocation['lng']);
      }

      return NavigationResult(
        success: true,
        steps: _steps,
        polylinePoints: _polylinePoints,
        destinationLatLng: _destinationLatLng,
        totalDistance: data['routes'][0]['legs'][0]['distance']['text'],
        totalDuration: data['routes'][0]['legs'][0]['duration']['text'],
      );
    } catch (e) {
      return NavigationResult(
        success: false,
        error: 'Error getting directions: $e',
      );
    }
  }

  /// What is around the user right now, nearest first.
  ///
  /// Backs the "what's nearby" voice command. Uses the Places Nearby Search
  /// endpoint, which needs the Places API enabled on the same key the
  /// Directions calls use - if it isn't, this reports a failure rather than
  /// throwing, and the caller says so out loud.
  Future<NearbyPlacesResult> findNearbyPlaces({
    required double latitude,
    required double longitude,
    int radiusMeters = 400,
    int limit = 5,
  }) async {
    if (useMock) {
      return NearbyPlacesResult(success: true, places: [
        const NearbyPlace(
            name: 'Central Cafe', category: 'cafe', distanceMeters: 40),
        const NearbyPlace(
            name: 'Oak Street Pharmacy',
            category: 'pharmacy',
            distanceMeters: 120),
        const NearbyPlace(
            name: 'Riverside Park', category: 'park', distanceMeters: 260),
      ]);
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      return NearbyPlacesResult(
        success: false,
        error: 'Google Maps API key not configured',
      );
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$latitude,$longitude'
        '&radius=$radiusMeters'
        '&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        return NearbyPlacesResult(
          success: false,
          error: 'Places request failed: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);
      final status = data['status'];

      // ZERO_RESULTS is a successful search that found nothing - a field in
      // the middle of nowhere is a valid answer, not an error.
      if (status == 'ZERO_RESULTS') {
        return NearbyPlacesResult(success: true, places: const []);
      }
      if (status != 'OK') {
        return NearbyPlacesResult(
          success: false,
          error: 'Places lookup failed: $status',
        );
      }

      return NearbyPlacesResult(
        success: true,
        places: parseNearbyPlaces(
          data,
          latitude: latitude,
          longitude: longitude,
          limit: limit,
        ),
      );
    } catch (e) {
      return NearbyPlacesResult(
        success: false,
        error: 'Error finding nearby places: $e',
      );
    }
  }

  /// Turns a Places response into the nearest [limit] places.
  ///
  /// Separate from the request so it can be tested against a fixture: the
  /// distance sort is the part that actually matters to someone who cannot
  /// see which way to walk, and it is not something the API does for us.
  @visibleForTesting
  static List<NearbyPlace> parseNearbyPlaces(
    Map<String, dynamic> data, {
    required double latitude,
    required double longitude,
    int limit = 5,
  }) {
    final results = data['results'];
    if (results is! List) return const [];

    final places = <NearbyPlace>[];
    for (final entry in results) {
      if (entry is! Map) continue;

      final name = entry['name'];
      final location = entry['geometry']?['location'];
      if (name is! String || name.isEmpty || location == null) continue;

      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      places.add(NearbyPlace(
        name: name,
        category: _primaryCategory(entry['types']),
        distanceMeters:
            _distanceMeters(latitude, longitude, lat, lng).round(),
        vicinity: entry['vicinity'] as String?,
      ));
    }

    places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return places.take(limit).toList(growable: false);
  }

  /// Places tags everything with a pile of types, most of them structural
  /// ("point_of_interest", "establishment"). Those say nothing useful out
  /// loud, so they are skipped in favour of the first real category.
  static const Set<String> _uselessTypes = {
    'point_of_interest',
    'establishment',
    'premise',
    'political',
    'geocode',
  };

  static String? _primaryCategory(Object? types) {
    if (types is! List) return null;
    for (final type in types) {
      if (type is String && !_uselessTypes.contains(type)) {
        return type.replaceAll('_', ' ');
      }
    }
    return null;
  }

  /// Haversine great-circle distance in metres.
  static double _distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// Get mock directions for testing
  NavigationResult _getMockDirections({
    required double originLat,
    required double originLng,
  }) {
    _steps = [
      NavigationStep(
        instruction: 'Head north on Main Street',
        distance: '50 m',
        distanceMeters: 50,
        duration: '1 min',
        maneuver: 'straight',
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
      ),
      NavigationStep(
        instruction: 'Turn right onto Oak Avenue',
        distance: '100 m',
        distanceMeters: 100,
        duration: '2 min',
        maneuver: 'turn-right',
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
      ),
      NavigationStep(
        instruction: 'Continue straight for 200 meters',
        distance: '200 m',
        distanceMeters: 200,
        duration: '3 min',
        maneuver: 'straight',
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
      ),
      NavigationStep(
        instruction: 'Turn left onto Elm Street',
        distance: '75 m',
        distanceMeters: 75,
        duration: '1 min',
        maneuver: 'turn-left',
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
      ),
      NavigationStep(
        instruction: 'Your destination is on the right',
        distance: '10 m',
        distanceMeters: 10,
        duration: '1 min',
        maneuver: 'arrive',
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
      ),
    ];

    _currentStepIndex = 0;
    _isNavigating = true;

    // Sample polyline points for mock mode
    _polylinePoints = [
      LatLng(originLat, originLng),
      LatLng(originLat + 0.001, originLng + 0.001),
      LatLng(originLat + 0.002, originLng + 0.002),
    ];
    _destinationLatLng = _polylinePoints.last;

    return NavigationResult(
      success: true,
      steps: _steps,
      polylinePoints: _polylinePoints,
      destinationLatLng: _destinationLatLng,
      totalDistance: '435 m',
      totalDuration: '8 min',
    );
  }

  /// Get current navigation step
  NavigationStep? getCurrentStep() {
    if (_steps.isEmpty || _currentStepIndex >= _steps.length) return null;
    return _steps[_currentStepIndex];
  }

  /// Get voice-friendly instruction for current step
  String getCurrentVoiceInstruction() {
    final step = getCurrentStep();
    if (step == null) return 'Navigation complete';

    String instruction = step.instruction;
    
    // Add distance context
    if (step.distanceMeters > 0) {
      if (step.distanceMeters < 50) {
        instruction = 'In ${step.distanceMeters} meters, $instruction';
      } else {
        instruction = 'In about ${step.distance}, $instruction';
      }
    }

    return instruction;
  }

  /// Move to next step
  bool nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      return true;
    }
    _isNavigating = false;
    return false;
  }

  /// Check if current step involves a turn
  bool isCurrentStepATurn() {
    final step = getCurrentStep();
    if (step == null) return false;
    return step.maneuver.contains('turn') || 
           step.maneuver.contains('left') || 
           step.maneuver.contains('right');
  }

  /// Get turn direction for haptic feedback
  bool? isLeftTurn() {
    final step = getCurrentStep();
    if (step == null) return null;
    if (step.maneuver.contains('left')) return true;
    if (step.maneuver.contains('right')) return false;
    return null;
  }

  /// Stop navigation
  void stopNavigation() {
    _steps = [];
    _currentStepIndex = 0;
    _isNavigating = false;
  }

  /// Launch native Google Maps for external navigation
  Future<bool> launchGoogleMaps(String destination) async {
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&travelmode=walking');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Clean HTML tags from instructions
  String _cleanHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
  }

  // Getters
  bool get isNavigating => _isNavigating;
  int get currentStepIndex => _currentStepIndex;
  int get totalSteps => _steps.length;
  List<NavigationStep> get steps => _steps;
  List<LatLng> get polylinePoints => _polylinePoints;
  LatLng? get destinationLatLng => _destinationLatLng;

  /// Decode encoded polyline string from Google Maps API
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }
}

/// Represents a single navigation step
class NavigationStep {
  final String instruction;
  final String distance;
  final int distanceMeters;
  final String duration;
  final String maneuver;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.distanceMeters,
    required this.duration,
    required this.maneuver,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });
}

/// Somewhere near the user, and how far away it is.
class NearbyPlace {
  final String name;

  /// Humanised Places type ("cafe", "bus station"), or null when the entry
  /// carried nothing but structural tags.
  final String? category;

  final int distanceMeters;
  final String? vicinity;

  const NearbyPlace({
    required this.name,
    required this.distanceMeters,
    this.category,
    this.vicinity,
  });
}

/// Result of a nearby-places lookup.
class NearbyPlacesResult {
  final bool success;
  final String? error;
  final List<NearbyPlace> places;

  const NearbyPlacesResult({
    required this.success,
    this.error,
    this.places = const [],
  });
}

/// Result of a directions request
class NavigationResult {
  final bool success;
  final String? error;
  final List<NavigationStep>? steps;
  final List<LatLng>? polylinePoints;
  final LatLng? destinationLatLng;
  final String? totalDistance;
  final String? totalDuration;

  NavigationResult({
    required this.success,
    this.error,
    this.steps,
    this.polylinePoints,
    this.destinationLatLng,
    this.totalDistance,
    this.totalDuration,
  });
}
