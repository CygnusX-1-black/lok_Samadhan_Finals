import '../models/department.dart';
import '../models/grievance.dart';

class MockGrievancesData {
  static List<Grievance> getInitialGrievances() {
    final now = DateTime.now();

    return [
      // 0. High Urgency Water Pipeline Issue (Gujarati - Gujarat)
      Grievance(
        id: 'LS-2026-72418',
        citizenPhone: '+91 98250 12345',
        citizenName: 'Hasmukhbhai Patel',
        spokenDialect: 'Gujarati (ગુજરાતી)',
        rawSpeechText: 'અમારા ગામમાં પીવાના પાણીની મુખ્ય પાઇપલાઇન તૂટી ગઈ છે, ૪ દિવસથી પાણીનો પુરવઠો બંધ છે. સાણંદ તાલુકો.',
        translatedText: 'Main drinking water supply pipeline broken in our village, water supply suspended for 4 days. Sanand Taluka.',
        departmentCategory: DepartmentCategory.waterSupply,
        villageWard: 'Sanand Village, Ward 3',
        block: 'Sanand Taluka',
        district: 'Ahmedabad',
        state: 'Gujarat',
        latitude: 22.9868,
        longitude: 72.3812,
        urgency: UrgencyLevel.high,
        aiConfidenceScore: 0.97,
        status: GrievanceStatus.underReview,
        createdAt: now.subtract(const Duration(hours: 3)),
        dueDate: now.add(const Duration(hours: 45)),
        auditLog: [
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 3)),
            statusLabel: 'Voice Grievance Registered',
            actor: 'Lok Samadhan Voice Gateway',
            description: 'Spoken language recognized: Gujarati (gu_IN). GPS: Lat 22.9868° N, Long 72.3812° E.',
          ),
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 2, minutes: 55)),
            statusLabel: 'Auto-Routed to PHED',
            actor: 'Lok Samadhan NLP Router',
            description: 'Routed to Drinking Water & Sanitation (PHED) Gujarat circle.',
          ),
        ],
      ),

      // 1. High Urgency Water Complaint (Bhojpuri - Bihar) - Received
      Grievance(
        id: 'LS-2026-89412',
        citizenPhone: '+91 98351 44102',
        citizenName: 'Rameshwar Mahato',
        spokenDialect: 'Bhojpuri',
        rawSpeechText: 'हमार टोला के चापाकल दु हफ्ता से बिगड़ल बा, पीने के पानी ना आवत बा। रामपुर वार्ड 4।',
        translatedText: 'Our village handpump has been broken for 2 weeks, drinking water supply stopped. Rampur Ward 4.',
        departmentCategory: DepartmentCategory.waterSupply,
        villageWard: 'Rampur Village, Ward 4',
        block: 'Bhojpur Sadar',
        district: 'Bhojpur',
        state: 'Bihar',
        latitude: 25.5941,
        longitude: 85.1376,
        urgency: UrgencyLevel.high,
        aiConfidenceScore: 0.94,
        status: GrievanceStatus.received,
        createdAt: now.subtract(const Duration(hours: 4)),
        dueDate: now.add(const Duration(hours: 44)),
        auditLog: [
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 4)),
            statusLabel: 'Voice Grievance Registered',
            actor: 'Lok Samadhan Mobile Gateway',
            description: 'GPS fetched: Lat 25.5941° N, Long 85.1376° E. Spoken language detected: Bhojpuri.',
          ),
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 3, minutes: 58)),
            statusLabel: 'AI Speech-to-Text & Auto-Routed',
            actor: 'Lok Samadhan NLP Router',
            description: 'Transcribed & mapped to Drinking Water & Sanitation (PHED) Queue.',
          ),
        ],
      ),

      // 2. Photo Grievance - Electrical Transformer Blast Hazard (DISCOM)
      Grievance(
        id: 'LS-2026-99201',
        citizenPhone: '+91 94140 88231',
        citizenName: 'Virendra Singh',
        spokenDialect: 'Hindi (Photo Multimodal AI)',
        rawSpeechText: '[Photo Uploaded] 11KV Transformer Explosion & Wire Snap Hazard.',
        translatedText: 'High Voltage 11KV Electrical Transformer caught fire and exploded, live wire hanging over main road.',
        departmentCategory: DepartmentCategory.electricity,
        villageWard: 'Grid Substation Colony, Ward 2',
        block: 'Bhojpur Sadar',
        district: 'Bhojpur',
        state: 'Bihar',
        latitude: 25.5992,
        longitude: 85.1412,
        photoUrl: 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=500',
        photoAnalysisSummary: 'AI Vision Analysis: Severe 11KV Transformer Fire Damage & Snapped High Tension Lines detected. High Safety Hazard.',
        urgency: UrgencyLevel.high,
        aiConfidenceScore: 0.98,
        status: GrievanceStatus.inProgress,
        createdAt: now.subtract(const Duration(hours: 1)),
        dueDate: now.add(const Duration(hours: 23)),
        auditLog: [
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 1)),
            statusLabel: 'Photo Grievance Captured',
            actor: 'Lok Samadhan AI Vision Pipeline',
            description: 'Photo EXIF GPS: Lat 25.5992° N, Long 85.1412° E. Auto-routed to DISCOM Electricity Office.',
          ),
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(minutes: 40)),
            statusLabel: 'Assigned to Lineman Team',
            actor: 'Assistant Engineer DISCOM',
            description: 'Line isolated remotely from substation. Repair crew dispatched to location.',
          ),
        ],
      ),

      // 3. Low Confidence Complaint - Flagged for HITL Review (Santali - Jharkhand)
      Grievance(
        id: 'LS-2026-89415',
        citizenPhone: '+91 94712 88201',
        citizenName: 'Sombari Tudu',
        spokenDialect: 'Santali',
        rawSpeechText: 'ᱟᱞᱮ ᱟᱛᱳ ᱨᱮᱱᱟᱜ ᱫᱟ elements ᱦᱮᱸᱰᱯᱟᱢᱯ ᱵᱟᱹᱲᱤᱡ ᱟᱠᱟᱱᱟ। ᱫᱩᱢᱠᱟ ᱥᱟᱫᱟᱨ।',
        translatedText: 'Drinking water handpump broken in tribal hamlet. Dumka Sadar.',
        departmentCategory: DepartmentCategory.waterSupply,
        villageWard: 'Kadamdihi Tribal Settlement',
        block: 'Dumka Sadar',
        district: 'Dumka',
        state: 'Jharkhand',
        latitude: 24.2676,
        longitude: 87.2498,
        urgency: UrgencyLevel.high,
        aiConfidenceScore: 0.68,
        status: GrievanceStatus.hitlReview,
        isHitlFallback: true,
        hitlReviewerNotes: 'Awaiting human review officer to verify spoken Santali dialect transcription.',
        createdAt: now.subtract(const Duration(hours: 2)),
        dueDate: now.add(const Duration(hours: 46)),
        auditLog: [
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 2)),
            statusLabel: 'Voice Call Recorded',
            actor: 'Lok Samadhan Audio Pipeline',
            description: 'Audio recorded in Santali. GPS: Lat 24.2676° N, Long 87.2498° E.',
          ),
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 1, minutes: 59)),
            statusLabel: 'Routed to HITL Queue',
            actor: 'Safety Net Fallback Engine',
            description: 'Low-confidence classification routed to Human Review Officer queue.',
          ),
        ],
      ),

      // 4. Overdue SLA & Escalated Complaint (PDS Ration - Uttar Pradesh)
      Grievance(
        id: 'LS-2026-54210',
        citizenPhone: '+91 97920 11984',
        citizenName: 'Kanti Devi',
        spokenDialect: 'Hindi (Awadhi)',
        rawSpeechText: 'कोटेदार राशन कार्ड पर गेहूं और चावल नहीं दे रहा है, 1 महीने से टाल रहा है।',
        translatedText: 'Fair price shop dealer refusing wheat and rice on ration card for over 1 month.',
        departmentCategory: DepartmentCategory.pdsRation,
        villageWard: 'Devkali Gram Panchayat',
        block: 'Harraiya',
        district: 'Basti',
        state: 'Uttar Pradesh',
        latitude: 26.7993,
        longitude: 82.7235,
        urgency: UrgencyLevel.high,
        aiConfidenceScore: 0.96,
        status: GrievanceStatus.escalated,
        escalationLevel: 2,
        createdAt: now.subtract(const Duration(hours: 60)),
        dueDate: now.subtract(const Duration(hours: 12)),
        auditLog: [
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 60)),
            statusLabel: 'Call Received via App',
            actor: 'Lok Samadhan System',
            description: 'Complaint registered and assigned 48-hour SLA window.',
          ),
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 12)),
            statusLabel: 'SLA Breached & Auto-Escalated',
            actor: 'Automated SLA Monitor',
            description: 'Department failed to respond within 48h. Escalated to Level 2: District Magistrate Basti.',
          ),
        ],
      ),

      // 5. Road Repair Complaint - Resolved (Tamil - Tamil Nadu)
      Grievance(
        id: 'LS-2026-66321',
        citizenPhone: '+91 94431 77652',
        citizenName: 'M. Shanmugam',
        spokenDialect: 'Tamil',
        rawSpeechText: 'எங்கள் கிராமத்து பிரதான சாலையில் பெரிய பள்ளம் உள்ளது, மழை நீரால் போக்குவரத்து பாதிப்பு.',
        translatedText: 'Huge pothole on main village road causing traffic congestion and accidents after rain.',
        departmentCategory: DepartmentCategory.roadsInfrastructure,
        villageWard: 'Vadipatti Main Road',
        block: 'Vadipatti',
        district: 'Madurai',
        state: 'Tamil Nadu',
        latitude: 10.0104,
        longitude: 77.9547,
        urgency: UrgencyLevel.medium,
        aiConfidenceScore: 0.91,
        status: GrievanceStatus.resolved,
        resolutionNote: 'Road patch work completed by PWD contractor. Bitumen resurfacing verified on site.',
        resolutionTimestamp: now.subtract(const Duration(hours: 5)),
        createdAt: now.subtract(const Duration(hours: 32)),
        dueDate: now.add(const Duration(hours: 40)),
        auditLog: [
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 32)),
            statusLabel: 'Grievance Lodged',
            actor: 'Lok Samadhan Tamil Engine',
            description: 'Routed to PWD Madurai Division.',
          ),
          GrievanceAuditStep(
            timestamp: now.subtract(const Duration(hours: 5)),
            statusLabel: 'Grievance Resolved & SMS Sent',
            actor: 'Assistant Executive Engineer PWD',
            description: 'Repair work completed. Automated SMS notice sent to citizen + voice feedback prompt.',
          ),
        ],
      ),
    ];
  }
}
