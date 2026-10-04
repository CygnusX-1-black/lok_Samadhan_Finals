import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class LocationProvider with ChangeNotifier {
  bool _isGpsEnabled = true;
  bool _isLocating = false;
  bool _isRealGpsAcquired = false;

  double? _latitude;
  double? _longitude;
  String? _villageWard;
  String? _district;
  String? _state;
  String _statusMessage = 'Initializing phone GPS...';

  LocationProvider() {
    fetchRealLocation();
  }

  bool get isGpsEnabled => _isGpsEnabled;
  bool get isLocating => _isLocating;
  bool get isRealGpsAcquired => _isRealGpsAcquired;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get villageWard => _villageWard;
  String? get district => _district;
  String? get state => _state;
  String get statusMessage => _statusMessage;

  // Formatted latitude string or fallback
  String get formattedLat => _latitude != null ? '${_latitude!.toStringAsFixed(5)}° N' : 'Locating...';
  String get formattedLng => _longitude != null ? '${_longitude!.toStringAsFixed(5)}° E' : 'Locating...';

  void setGpsEnabled(bool enabled) {
    _isGpsEnabled = enabled;
    if (!enabled) {
      _isRealGpsAcquired = false;
      _statusMessage = 'Phone Location (GPS) is turned OFF.';
    } else {
      fetchRealLocation();
    }
    notifyListeners();
  }

  Future<void> fetchRealLocation() async {
    if (!_isGpsEnabled) return;

    _isLocating = true;
    _statusMessage = 'Acquiring live GPS satellite fix from phone...';
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLocating = false;
        _isRealGpsAcquired = false;
        _statusMessage = 'Location Services disabled on phone. Enable GPS in Settings.';
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isLocating = false;
          _isRealGpsAcquired = false;
          _statusMessage = 'Location permission denied. Tap to grant permission.';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLocating = false;
        _isRealGpsAcquired = false;
        _statusMessage = 'Location permission permanently denied. Open App Settings.';
        notifyListeners();
        return;
      }

      // Check last known location first for fast response
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        _latitude = lastPos.latitude;
        _longitude = lastPos.longitude;
        _isRealGpsAcquired = true;
        _statusMessage = 'Live Phone GPS: ${_latitude!.toStringAsFixed(5)}° N, ${_longitude!.toStringAsFixed(5)}° E';
        notifyListeners();
      }

      // Query current high precision location
      final currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      _latitude = currentPos.latitude;
      _longitude = currentPos.longitude;
      _isRealGpsAcquired = true;
      _isLocating = false;
      _statusMessage = 'Live Phone GPS: ${_latitude!.toStringAsFixed(5)}° N, ${_longitude!.toStringAsFixed(5)}° E';
      notifyListeners();

      // Reverse geocode via OpenStreetMap Nominatim on backend
      try {
        final osmData = await ApiService().reverseGeocode(_latitude!, _longitude!);
        if (osmData != null) {
          _villageWard = osmData['villageWard']?.toString();
          _district = osmData['district']?.toString();
          _state = osmData['state']?.toString();
          _statusMessage = '📍 $_villageWard, $_district (${_latitude!.toStringAsFixed(4)}°, ${_longitude!.toStringAsFixed(4)}°)';
          notifyListeners();
        }
      } catch (err) {
        debugPrint('[LocationProvider] OSM reverse geocode error: $err');
      }
    } catch (e) {
      debugPrint('Global LocationProvider error: $e');
      _isLocating = false;
      if (_latitude == null) {
        _statusMessage = 'GPS searching... Ensure location permission is granted.';
      }
      notifyListeners();
    }
  }

  Future<void> requestPermissionAndEnableGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.requestPermission();
    }
    await fetchRealLocation();
  }
}
