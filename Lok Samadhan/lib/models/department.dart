import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum DepartmentCategory {
  waterSupply,
  electricity,
  roadsInfrastructure,
  sanitationHealth,
  pdsRation,
  pensionsWelfare,
  policeLawOrder,
  generalPanchayat,
}

class DepartmentInfo {
  final DepartmentCategory category;
  final String code;
  final String nameEn;
  final String nameHi;
  final String nameGu;
  final String nodalAuthority;
  final int defaultSlaHours;
  final IconData icon;
  final Color color;

  const DepartmentInfo({
    required this.category,
    required this.code,
    required this.nameEn,
    required this.nameHi,
    required this.nameGu,
    required this.nodalAuthority,
    required this.defaultSlaHours,
    required this.icon,
    required this.color,
  });

  static const List<DepartmentInfo> allDepartments = [
    DepartmentInfo(
      category: DepartmentCategory.waterSupply,
      code: 'PHED-WTR',
      nameEn: 'Drinking Water & Sanitation (PHED)',
      nameHi: 'पेयजल एवं स्वच्छता विभाग',
      nameGu: 'પીવાનું પાણી અને સ્વચ્છતા વિભાગ (PHED)',
      nodalAuthority: 'Public Health Engineering Department',
      defaultSlaHours: 48,
      icon: Icons.water_drop_outlined,
      color: Color(0xFF0284C7),
    ),
    DepartmentInfo(
      category: DepartmentCategory.electricity,
      code: 'DISCOM-ELEC',
      nameEn: 'Electricity Distribution (DISCOM)',
      nameHi: 'विद्युत वितरण निगम',
      nameGu: 'વીજળી વિતરણ નિગમ (DISCOM)',
      nodalAuthority: 'State Electricity Board',
      defaultSlaHours: 24,
      icon: Icons.electric_bolt_outlined,
      color: Color(0xFFD97706),
    ),
    DepartmentInfo(
      category: DepartmentCategory.roadsInfrastructure,
      code: 'PWD-ROAD',
      nameEn: 'Public Works & Roads (PWD)',
      nameHi: 'लोक निर्माण विभाग (सड़क)',
      nameGu: 'માર્ગ અને મકાન વિભાગ - રસ્તા (PWD)',
      nodalAuthority: 'Public Works Department',
      defaultSlaHours: 72,
      icon: Icons.add_road_outlined,
      color: Color(0xFF4B5563),
    ),
    DepartmentInfo(
      category: DepartmentCategory.sanitationHealth,
      code: 'HLTH-SANI',
      nameEn: 'Public Health & Local Sanitation',
      nameHi: 'स्वास्थ्य एवं स्वच्छता विभाग',
      nameGu: 'જાહેર આરોગ્ય અને સ્થાનિક સ્વચ્છતા વિભાગ',
      nodalAuthority: 'Chief Medical Officer / Municipal Corp',
      defaultSlaHours: 36,
      icon: Icons.health_and_safety_outlined,
      color: Color(0xFF059669),
    ),
    DepartmentInfo(
      category: DepartmentCategory.pdsRation,
      code: 'FCS-PDS',
      nameEn: 'Food & Civil Supplies (PDS Ration)',
      nameHi: 'खाद्य एवं नागरिक आपूर्ति (राशन)',
      nameGu: 'અન્ન અને નાગરિક પુરવઠો - રાશન (PDS)',
      nodalAuthority: 'District Supply Office',
      defaultSlaHours: 48,
      icon: Icons.shopping_basket_outlined,
      color: Color(0xFFEA580C),
    ),
    DepartmentInfo(
      category: DepartmentCategory.pensionsWelfare,
      code: 'SOC-WELF',
      nameEn: 'Social Welfare & Pension Schemes',
      nameHi: 'समाज कल्याण एवं पेंशन विभाग',
      nameGu: 'સમાજ કલ્યાણ અને પેન્શન યોજનાઓ વિભાગ',
      nodalAuthority: 'District Social Welfare Office',
      defaultSlaHours: 96,
      icon: Icons.family_restroom_outlined,
      color: Color(0xFF7C3AED),
    ),
    DepartmentInfo(
      category: DepartmentCategory.policeLawOrder,
      code: 'POL-LAW',
      nameEn: 'Police & Public Safety',
      nameHi: 'पुलिस एवं जन सुरक्षा',
      nameGu: 'પોલીસ અને જાહેર સુરક્ષા',
      nodalAuthority: 'Superintendent of Police (SP Office)',
      defaultSlaHours: 12,
      icon: Icons.local_police_outlined,
      color: Color(0xFFDC2626),
    ),
    DepartmentInfo(
      category: DepartmentCategory.generalPanchayat,
      code: 'PRD-GEN',
      nameEn: 'Panchayati Raj & General Grievance',
      nameHi: 'पंचायती राज एवं सामान्य शिकायत',
      nameGu: 'પંચાયતી રાજ અને સામાન્ય ફરિયાદ',
      nodalAuthority: 'Block Development Officer (BDO)',
      defaultSlaHours: 48,
      icon: Icons.account_balance_outlined,
      color: AppColors.navyMedium,
    ),
  ];

  String nameForDialect(String dialectId) {
    if (dialectId == 'gujarati') return nameGu;
    if (dialectId == 'hindi' || dialectId == 'bhojpuri' || dialectId == 'marwari') return nameHi;
    return nameEn;
  }

  static DepartmentInfo getByCategory(DepartmentCategory cat) {
    return allDepartments.firstWhere(
      (d) => d.category == cat,
      orElse: () => allDepartments.last,
    );
  }
}
