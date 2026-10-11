import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class GpsResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final double? accuracy; // in meters
  final DateTime? capturedAt;
  final String? villageWard;
  final String? block;
  final String? district;
  final String? state;
  final String? errorMessage;
  final bool isPermissionDenied;
  final bool isPermanentlyDenied;
  final bool isServiceDisabled;

  const GpsResult({
    required this.success,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.capturedAt,
    this.villageWard,
    this.block,
    this.district,
    this.state,
    this.errorMessage,
    this.isPermissionDenied = false,
    this.isPermanentlyDenied = false,
    this.isServiceDisabled = false,
  });
}

class LocationProvider with ChangeNotifier {
  bool _isGpsEnabled = true;
  bool _isLocating = false;
  bool _isRealGpsAcquired = false;

  double? _latitude;
  double? _longitude;
  double? _accuracy;
  DateTime? _capturedAt;
  String? _villageWard;
  String? _block;
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
  double? get accuracy => _accuracy;
  DateTime? get capturedAt => _capturedAt;
  String? get villageWard => _villageWard;
  String? get block => _block;
  String? get district => _district;
  String? get state => _state;
  String get statusMessage => _statusMessage;

  // Formatted latitude string
  String get formattedLat {
    if (_latitude == null) return 'Location not available';
    final lat = _latitude!;
    final dir = lat >= 0 ? 'N' : 'S';
    return '${lat.abs().toStringAsFixed(5)}° $dir';
  }

  // Formatted longitude string
  String get formattedLng {
    if (_longitude == null) return 'Location not available';
    final lng = _longitude!;
    final dir = lng >= 0 ? 'E' : 'W';
    return '${lng.abs().toStringAsFixed(5)}° $dir';
  }

  String get formattedAccuracy {
    if (_accuracy != null && _accuracy! > 0) {
      return '±${_accuracy!.toStringAsFixed(0)} meters';
    }
    return '';
  }

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

  /// Acquires fresh, high-accuracy GPS coordinates for lodging a complaint.
  /// Handles platform permissions (Web, Android, iOS), timeouts, and validation.
  Future<GpsResult> acquireFreshGps({BuildContext? context}) async {
    if (!_isGpsEnabled) {
      return const GpsResult(
        success: false,
        isServiceDisabled: true,
        errorMessage: 'Location is turned off in the app. Please turn it on to capture GPS coordinates.',
      );
    }

    _isLocating = true;
    _statusMessage = 'Acquiring high-precision live GPS satellite fix...';
    notifyListeners();

    try {
      // 1. Check if device location services are enabled
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(const Duration(milliseconds: 600));
      } catch (_) {
        serviceEnabled = false;
      }

      if (!serviceEnabled) {
        _isLocating = false;
        _statusMessage = 'Location Services disabled on device. Enable GPS in Settings.';
        notifyListeners();
        return const GpsResult(
          success: false,
          isServiceDisabled: true,
          errorMessage: 'Device Location Services are disabled. Please turn on GPS in your device settings.',
        );
      }

      // 2. Check and request location permission
      LocationPermission permission = LocationPermission.denied;
      try {
        permission = await Geolocator.checkPermission().timeout(const Duration(milliseconds: 600));
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission().timeout(const Duration(seconds: 15));
        }
      } catch (_) {
        permission = LocationPermission.denied;
      }

      if (permission == LocationPermission.denied) {
        _isLocating = false;
        _statusMessage = 'Location permission denied. Grant permission to capture accurate complaint GPS.';
        notifyListeners();
        return const GpsResult(
          success: false,
          isPermissionDenied: true,
          errorMessage: 'Location permission was denied. Lok Samadhan requires location to attach accurate GPS coordinates to civic complaints.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        _isLocating = false;
        _statusMessage = 'Location permission permanently denied. Open App Settings to allow.';
        notifyListeners();
        return const GpsResult(
          success: false,
          isPermanentlyDenied: true,
          errorMessage: 'Location permission is permanently denied. Please enable location permission in your device settings.',
        );
      }

      // 3. Request fresh position with best accuracy and 15s timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      // 4. Validate coordinates bounds (-90 to 90, -180 to 180)
      if (position.latitude < -90 || position.latitude > 90 || position.longitude < -180 || position.longitude > 180) {
        throw Exception('Captured GPS coordinates out of valid range: (${position.latitude}, ${position.longitude})');
      }

      _latitude = position.latitude;
      _longitude = position.longitude;
      _accuracy = position.accuracy;
      _capturedAt = DateTime.now().toUtc();
      _isRealGpsAcquired = true;
      _isLocating = false;

      final latDir = _latitude! >= 0 ? 'N' : 'S';
      final lonDir = _longitude! >= 0 ? 'E' : 'W';
      final accStr = _accuracy != null ? ' (±${_accuracy!.toStringAsFixed(0)}m)' : '';
      _statusMessage = 'Live Phone GPS: ${_latitude!.abs().toStringAsFixed(5)}° $latDir, ${_longitude!.abs().toStringAsFixed(5)}° $lonDir$accStr';
      notifyListeners();

      // 5. Reverse geocode via OpenStreetMap Nominatim on backend
      try {
        final osmData = await ApiService().reverseGeocode(_latitude!, _longitude!);
        if (osmData != null) {
          _villageWard = osmData['villageWard']?.toString();
          _block = osmData['block']?.toString();
          _district = osmData['district']?.toString();
          _state = osmData['state']?.toString();
          _statusMessage = '📍 $_villageWard, $_district (${_latitude!.abs().toStringAsFixed(4)}° $latDir, ${_longitude!.abs().toStringAsFixed(4)}° $lonDir$accStr)';
          notifyListeners();
        }
      } catch (err) {
        debugPrint('[LocationProvider] OSM reverse geocode error: $err');
      }

      return GpsResult(
        success: true,
        latitude: _latitude,
        longitude: _longitude,
        accuracy: _accuracy,
        capturedAt: _capturedAt,
        villageWard: _villageWard,
        block: _block,
        district: _district,
        state: _state,
      );
    } catch (e) {
      debugPrint('[LocationProvider] acquireFreshGps error: $e');
      _isLocating = false;
      _statusMessage = 'GPS fix could not be acquired. Ensure location is enabled and retry.';
      notifyListeners();
      return GpsResult(
        success: false,
        errorMessage: 'Failed to acquire GPS fix: ${e.toString()}',
      );
    }
  }

  /// Initial or background fetch
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

      // Check last known location first for fast initial UI display
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        _latitude = lastPos.latitude;
        _longitude = lastPos.longitude;
        _accuracy = lastPos.accuracy;
        _capturedAt = DateTime.now().toUtc();
        _isRealGpsAcquired = true;
        final latDir = _latitude! >= 0 ? 'N' : 'S';
        final lonDir = _longitude! >= 0 ? 'E' : 'W';
        _statusMessage = 'Live Phone GPS: ${_latitude!.abs().toStringAsFixed(5)}° $latDir, ${_longitude!.abs().toStringAsFixed(5)}° $lonDir';
        notifyListeners();
      }

      // Query current high precision location
      final currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      _latitude = currentPos.latitude;
      _longitude = currentPos.longitude;
      _accuracy = currentPos.accuracy;
      _capturedAt = DateTime.now().toUtc();
      _isRealGpsAcquired = true;
      _isLocating = false;

      final latDir = _latitude! >= 0 ? 'N' : 'S';
      final lonDir = _longitude! >= 0 ? 'E' : 'W';
      final accStr = _accuracy != null ? ' (±${_accuracy!.toStringAsFixed(0)}m)' : '';
      _statusMessage = 'Live Phone GPS: ${_latitude!.abs().toStringAsFixed(5)}° $latDir, ${_longitude!.abs().toStringAsFixed(5)}° $lonDir$accStr';
      notifyListeners();

      // Reverse geocode via OpenStreetMap Nominatim on backend
      try {
        final osmData = await ApiService().reverseGeocode(_latitude!, _longitude!);
        if (osmData != null) {
          _villageWard = osmData['villageWard']?.toString();
          _block = osmData['block']?.toString();
          _district = osmData['district']?.toString();
          _state = osmData['state']?.toString();
          _statusMessage = '📍 $_villageWard, $_district (${_latitude!.abs().toStringAsFixed(4)}° $latDir, ${_longitude!.abs().toStringAsFixed(4)}° $lonDir$accStr)';
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

  /// Shows the standard runtime explanation dialog required by civic apps
  static Future<bool> showLocationExplanationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.saffronPrimary),
            const SizedBox(width: 8),
            Text(
              'Location Access Required',
              style: GoogleFonts.notoSans(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Lok Samadhan uses your location to attach accurate GPS coordinates to your civic complaint so the responsible department can identify the correct location.',
          style: GoogleFonts.notoSans(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.notoSans(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffronPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Grant Permission', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
