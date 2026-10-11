import 'package:flutter_test/flutter_test.dart';
import 'package:sahayak_vaani/utils/time_utils.dart';
import 'package:sahayak_vaani/models/grievance.dart';
import 'package:sahayak_vaani/models/department.dart';

void main() {
  group('Asia/Kolkata Timezone (IST) Verification Tests', () {
    test('Formats UTC database timestamp to Asia/Kolkata local time', () {
      // Test database timestamp specified in requirements
      const dbTimestamp = '2026-10-10T06:22:01.067+00:00';
      final formatted = TimeUtils.formatKolkataTime(dbTimestamp);
      expect(formatted, equals('10 Oct 2026, 11:52 AM'));
    });

    test('Formats ISO-8601 UTC Z timestamp to Asia/Kolkata local time', () {
      const dbTimestampZ = '2026-10-10T06:22:01.067Z';
      final formatted = TimeUtils.formatKolkataTime(dbTimestampZ);
      expect(formatted, equals('10 Oct 2026, 11:52 AM'));
    });

    test('Formats DateTime object in Kolkata time regardless of machine timezone', () {
      final utcDateTime = DateTime.utc(2026, 10, 10, 6, 22, 1);
      final formatted = TimeUtils.formatKolkataTime(utcDateTime);
      expect(formatted, equals('10 Oct 2026, 11:52 AM'));
    });

    test('Correctly handles PM times and midnight transitions', () {
      // 14:30 UTC -> 20:00 IST (8:00 PM)
      const eveningUtc = '2026-10-10T14:30:00.000+00:00';
      expect(TimeUtils.formatKolkataTime(eveningUtc), equals('10 Oct 2026, 8:00 PM'));

      // 19:00 UTC on 10 Oct -> 00:30 IST on 11 Oct (Next Day)
      const midnightUtc = '2026-10-10T19:00:00.000+00:00';
      expect(TimeUtils.formatKolkataTime(midnightUtc), equals('11 Oct 2026, 12:30 AM'));
    });

    test('Handles null, empty, and invalid dates gracefully', () {
      expect(TimeUtils.formatKolkataTime(null), equals('Time unavailable'));
      expect(TimeUtils.formatKolkataTime(''), equals('Time unavailable'));
      expect(TimeUtils.formatKolkataTime('  '), equals('Time unavailable'));
      expect(TimeUtils.formatKolkataTime('not-a-date'), equals('Invalid date'));
    });

    test('Preserves underlying Grievance DateTime values and SLA calculations', () {
      final now = DateTime.utc(2026, 10, 10, 6, 22, 1);
      final dueDate = now.add(const Duration(hours: 48));

      final grievance = Grievance(
        id: 'LS-2026-TEST01',
        citizenPhone: '9876543210',
        citizenName: 'Citizen Test',
        spokenDialect: 'Hindi',
        rawSpeechText: 'Test Problem',
        translatedText: 'Test Problem Translated',
        departmentCategory: DepartmentCategory.waterSupply,
        villageWard: 'Ward 1',
        block: 'Block A',
        district: 'Patna',
        state: 'Bihar',
        latitude: 25.5941,
        longitude: 85.1376,
        urgency: UrgencyLevel.medium,
        aiConfidenceScore: 0.95,
        status: GrievanceStatus.received,
        isHitlFallback: false,
        createdAt: now,
        dueDate: dueDate,
        auditLog: [
          GrievanceAuditStep(
            timestamp: now,
            statusLabel: 'Complaint Lodged',
            actor: 'System',
            description: 'Lodged via Test',
          ),
        ],
      );

      // Verify that original UTC values are untouched
      expect(grievance.createdAt, equals(now));
      expect(grievance.dueDate, equals(dueDate));
      expect(grievance.dueDate.difference(grievance.createdAt).inHours, equals(48));

      // Verify display strings use Kolkata time
      expect(TimeUtils.formatKolkataTime(grievance.createdAt), equals('10 Oct 2026, 11:52 AM'));
      expect(TimeUtils.formatKolkataTime(grievance.auditLog.first.timestamp), equals('10 Oct 2026, 11:52 AM'));
    });
  });
}
