import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/grievance_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_utils.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/sms_notification_sheet.dart';

class MyGrievancesScreen extends StatelessWidget {
  const MyGrievancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isGuj = langProvider.isGujarati;
    final grievances = grievanceProvider.grievances;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGuj ? 'મારી નોંધાયેલ ફરિયાદો (My Grievances)' : 'मेरी दर्ज शिकायतें (My Grievances)',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isGuj
                          ? 'તમારા ફોન પરથી નોંધાયેલ લાઈવ ફરિયાદો'
                          : 'Real-time grievances registered from your phone',
                      style: GoogleFonts.notoSans(fontSize: 11.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                icon: const Icon(Icons.sms_outlined, size: 16, color: AppColors.navyDark),
                label: Text('SMS (${grievanceProvider.smsNotifications.length})', style: const TextStyle(fontSize: 12)),
                onPressed: () => SmsNotificationSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: grievances.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.amberOrangeBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.inbox_outlined, color: AppColors.saffronPrimary, size: 48),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Grievances Lodged Yet',
                            style: GoogleFonts.notoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isGuj ? 'હજુ સુધી કોઈ ફરિયાદ નોંધાયેલ નથી' : 'कोई शिकायत दर्ज नहीं की गई है',
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Lodge a grievance via Voice Lodge (बोलकर दर्ज करें) or AI Photo Lodge (तस्वीर से दर्ज करें). Your real complaint will appear here instantly!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: grievances.length,
                    itemBuilder: (context, index) {
                      final g = grievances[index];
                      return ComplaintCard(
                        grievance: g,
                        onTap: () {
                          _showGrievanceDetails(context, g);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showGrievanceDetails(BuildContext context, dynamic g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Complaint Details (${g.id})',
                      style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(c),
                  ),
                ],
              ),
              const Divider(),

              // Display Submitted Photo if present
              if (g.photoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      children: [
                        kIsWeb || g.photoUrl!.startsWith('http')
                            ? Image.network(
                                g.photoUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(g.photoUrl!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, color: AppColors.emeraldPrimary, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  g.hasValidGps ? 'GPS: ${g.formattedGps}' : 'Location not available',
                                  style: GoogleFonts.notoSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              Text('Channel / Method: ${g.spokenDialect}', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Complaint Description: "${g.translatedText.isNotEmpty ? g.translatedText : g.rawSpeechText}"', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text('Assigned Nodal Department:', style: GoogleFonts.notoSans(fontWeight: FontWeight.w700)),
              Text('${g.departmentInfo.nameEn} (${g.departmentInfo.nameHi})'),
              const SizedBox(height: 12),
              Text('Location: ${g.villageWard}, ${g.district}, ${g.state}'),
              Text(g.hasValidGps ? 'GPS Coordinates: ${g.formattedGps}${g.formattedAccuracy.isNotEmpty ? " (${g.formattedAccuracy})" : ""}' : 'GPS Coordinates: Location not available', style: GoogleFonts.notoSans(color: AppColors.emeraldPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Text('Audit Trail:', style: GoogleFonts.notoSans(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...g.auditLog.map<Widget>((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• [${step.statusLabel}] (${TimeUtils.formatKolkataTime(step.timestamp)}) ${step.actor}: ${step.description}'),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
