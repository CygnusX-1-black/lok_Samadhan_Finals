import 'package:flutter_test/flutter_test.dart';
import 'package:sahayak_vaani/models/department.dart';
import 'package:sahayak_vaani/models/grievance.dart';
import 'package:sahayak_vaani/providers/grievance_provider.dart';
import 'package:sahayak_vaani/providers/location_provider.dart';

void main() {
  group('GPS Location System Tests (Section 7)', () {
    test('Test A & E: Real coordinates are preserved exactly and formatted with direction', () {
      const realLat = 22.5726;
      const realLon = 88.3639;
      const accuracy = 12.0;

      final grievance = Grievance(
        id: 'LS-2026-TEST01',
        citizenPhone: '+91 98765 43210',
        citizenName: 'Kolkata Citizen',
        spokenDialect: 'Bengali / Hindi',
        rawSpeechText: 'Water pipe leaking near park entrance',
        translatedText: 'Water pipe leaking near park entrance',
        departmentCategory: DepartmentCategory.waterSupply,
        villageWard: 'Ward 45, Kolkata Municipal',
        block: 'Central Kolkata',
        district: 'Kolkata',
        state: 'West Bengal',
        latitude: realLat,
        longitude: realLon,
        gpsAccuracyM: accuracy,
        urgency: UrgencyLevel.medium,
        aiConfidenceScore: 0.95,
        status: GrievanceStatus.received,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(hours: 48)),
        auditLog: const [],
      );

      // Verify exact coordinates are preserved
      expect(grievance.latitude, equals(realLat));
      expect(grievance.longitude, equals(realLon));
      expect(grievance.gpsAccuracyM, equals(accuracy));
      expect(grievance.hasValidGps, isTrue);

      // Verify formatted coordinates: 22.5726° N, 88.3639° E
      expect(grievance.formattedGps, contains('22.5726° N, 88.3639° E'));
      expect(grievance.formattedAccuracy, equals('±12 meters'));

      // Test E: Serializing to JSON and deserializing preserves the exact saved coordinates
      final json = grievance.toJson();
      expect(json['latitude'], equals(realLat));
      expect(json['longitude'], equals(realLon));
      expect(json['gpsAccuracyM'], equals(accuracy));

      final restored = Grievance.fromJson(json);
      expect(restored.latitude, equals(realLat));
      expect(restored.longitude, equals(realLon));
      expect(restored.gpsAccuracyM, equals(accuracy));
      expect(restored.formattedGps, equals(grievance.formattedGps));
    });

    test('Test B: Two complaints from different locations do not inherit coordinates', () {
      final provider = GrievanceProvider();

      // Complaint 1 from Location A (e.g., Delhi: 28.6139, 77.2090)
      final g1 = provider.lodgePhotoGrievance(
        problemTitle: 'Pothole in Connaught Place',
        detailedDescription: 'Large road crater near circle',
        category: DepartmentCategory.roadsInfrastructure,
        villageWard: 'Ward 12, New Delhi',
        district: 'New Delhi',
        state: 'Delhi',
        latitude: 28.6139,
        longitude: 77.2090,
        gpsAccuracyM: 8.0,
        photoUrl: '/path/photo1.jpg',
        photoAnalysisSummary: 'Pothole detected',
        citizenPhone: '+91 91111 22222',
        citizenName: 'Delhi Nagarik',
      );

      // Complaint 2 from Location B (e.g., Bangalore: 12.9716, 77.5946)
      final g2 = provider.lodgePhotoGrievance(
        problemTitle: 'Broken street light in Indiranagar',
        detailedDescription: 'Pole not working at night',
        category: DepartmentCategory.electricity,
        villageWard: 'Ward 80, Indiranagar',
        district: 'Bengaluru Urban',
        state: 'Karnataka',
        latitude: 12.9716,
        longitude: 77.5946,
        gpsAccuracyM: 15.0,
        photoUrl: '/path/photo2.jpg',
        photoAnalysisSummary: 'Dark street',
        citizenPhone: '+91 93333 44444',
        citizenName: 'Bengaluru Nagarik',
      );

      expect(g1.latitude, equals(28.6139));
      expect(g1.longitude, equals(77.2090));
      expect(g2.latitude, equals(12.9716));
      expect(g2.longitude, equals(77.5946));

      // Assert independent coordinates
      expect(g1.latitude, isNot(equals(g2.latitude)));
      expect(g1.longitude, isNot(equals(g2.longitude)));
      expect(g1.formattedGps, contains('28.6139° N, 77.2090° E'));
      expect(g2.formattedGps, contains('12.9716° N, 77.5946° E'));
    });

    test('Test C & D: Missing or denied GPS does NOT fabricate coordinates or default to Patna', () {
      final grievanceWithoutGps = Grievance(
        id: 'LS-2026-NOGPS',
        citizenPhone: '+91 98765 00000',
        citizenName: 'Citizen Without GPS',
        spokenDialect: 'Hindi',
        rawSpeechText: 'Water issue reported via landline/offline',
        translatedText: 'Water issue reported',
        departmentCategory: DepartmentCategory.waterSupply,
        villageWard: 'Rural Ward',
        block: 'Rural Block',
        district: 'Rural District',
        state: 'State',
        latitude: null,
        longitude: null,
        gpsAccuracyM: null,
        urgency: UrgencyLevel.low,
        aiConfidenceScore: 0.88,
        status: GrievanceStatus.received,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(hours: 48)),
        auditLog: const [],
      );

      expect(grievanceWithoutGps.latitude, isNull);
      expect(grievanceWithoutGps.longitude, isNull);
      expect(grievanceWithoutGps.hasValidGps, isFalse);
      expect(grievanceWithoutGps.formattedGps, equals('Location not available'));
      expect(grievanceWithoutGps.formattedGps, isNot(contains('25.5941')));
      expect(grievanceWithoutGps.formattedGps, isNot(contains('85.1376')));

      // Deserialization with missing/null coordinates does NOT inject Patna defaults
      final json = {
        'id': 'LS-2026-NOGPS-JSON',
        'citizenPhone': '+91 98765 00000',
        'citizenName': 'Citizen',
        'spokenDialect': 'Hindi',
        'rawSpeechText': 'Test speech',
        'translatedText': 'Test translated',
        'departmentCategory': 'waterSupply',
        'villageWard': 'Ward 1',
        'block': 'Block 1',
        'district': 'Dist',
        'state': 'State',
        'latitude': null,
        'longitude': null,
        'urgency': 'low',
        'aiConfidenceScore': 0.9,
        'status': 'received',
      };

      final parsed = Grievance.fromJson(json);
      expect(parsed.latitude, isNull);
      expect(parsed.longitude, isNull);
      expect(parsed.hasValidGps, isFalse);
      expect(parsed.formattedGps, equals('Location not available'));
    });

    test('LocationProvider GpsResult correctly handles denied permission without fabricating GPS', () {
      const result = GpsResult(
        success: false,
        isPermissionDenied: true,
        errorMessage: 'Location permission was denied by user.',
      );

      expect(result.success, isFalse);
      expect(result.latitude, isNull);
      expect(result.longitude, isNull);
      expect(result.isPermissionDenied, isTrue);
      expect(result.errorMessage, contains('denied'));
    });
  });
}
