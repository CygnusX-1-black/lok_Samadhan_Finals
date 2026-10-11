import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/grievance.dart';
import '../../providers/grievance_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_utils.dart';
import '../../widgets/complaint_card.dart';

class TrackGrievanceScreen extends StatefulWidget {
  const TrackGrievanceScreen({super.key});

  @override
  State<TrackGrievanceScreen> createState() => _TrackGrievanceScreenState();
}

class _TrackGrievanceScreenState extends State<TrackGrievanceScreen> {
  final TextEditingController _idController = TextEditingController();
  Grievance? _searchedGrievance;
  bool _hasSearched = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _idController.text.trim();
    if (query.isEmpty) return;

    final grievanceProvider = Provider.of<GrievanceProvider>(context, listen: false);
    var grievance = grievanceProvider.getGrievanceById(query);
    if (grievance == null) {
      try {
        grievance = await ApiService().getGrievanceById(query);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _hasSearched = true;
        _searchedGrievance = grievance;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isGuj = langProvider.isGujarati;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Text(
            isGuj
                ? 'તમારી ફરિયાદની સ્થિતિ જાણો (Track Complaint)'
                : 'अपनी शिकायत की स्थिति जानें (Track Complaint)',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isGuj
                ? 'તમારો ફરિયાદ ID દાખલ કરીને લાઈવ સ્થિતિ અને અધિકારીની પ્રગતિ તપાસો.'
                : 'Enter your Complaint ID to track live status and nodal officer progress.',
            style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Search Box & Track Status Button (No Voice Search Button)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      hintText: 'e.g. LS-2026-89412',
                      labelText: 'Complaint ID (शिकायत संख्या)',
                      prefixIcon: const Icon(Icons.tag),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: AppColors.saffronPrimary),
                        onPressed: _performSearch,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffronPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(
                        isGuj ? 'સ્થિતિ તપાસો (Track Status)' : 'Track Status (स्थिति देखें)',
                        style: GoogleFonts.notoSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      onPressed: _performSearch,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Search Result View
          if (_hasSearched) ...[
            if (_searchedGrievance != null) ...[
              Text(
                'Complaint Found:',
                style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              ComplaintCard(
                grievance: _searchedGrievance!,
                onTap: () => _showAuditTimelineModal(context, _searchedGrievance!),
              ),
              const SizedBox(height: 16),
              _buildTimelineWidget(_searchedGrievance!),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No Grievance Found',
                      style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please check the Complaint ID and try again, or check the "My Grievances" page.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Quick Helper Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.saffronPrimary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to get your Complaint ID?',
                          style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your Complaint ID is sent via SMS upon lodging and can also be viewed anytime on the "My Grievances" tab.',
                          style: GoogleFonts.notoSans(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineWidget(Grievance g) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit & Progress Trail (प्रगति विवरण)',
              style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: g.auditLog.length,
              itemBuilder: (context, index) {
                final step = g.auditLog[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.saffronPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (index < g.auditLog.length - 1)
                          Container(width: 2, height: 40, color: AppColors.cardBorder),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(step.statusLabel, style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w700)),
                              ),
                              Text(
                                TimeUtils.formatKolkataTime(step.timestamp),
                                style: GoogleFonts.notoSans(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Actor: ${step.actor}', style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.navyMedium, fontWeight: FontWeight.w600)),
                          Text(step.description, style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAuditTimelineModal(BuildContext context, Grievance g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(child: _buildTimelineWidget(g)),
      ),
    );
  }
}
