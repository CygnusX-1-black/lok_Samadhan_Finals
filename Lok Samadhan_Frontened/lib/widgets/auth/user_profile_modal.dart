import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';

class UserProfileModal extends StatelessWidget {
  final VoidCallback? onNavigateToMyGrievances;
  final VoidCallback? onNavigateToTrackStatus;

  const UserProfileModal({
    super.key,
    this.onNavigateToMyGrievances,
    this.onNavigateToTrackStatus,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onNavigateToMyGrievances,
    VoidCallback? onNavigateToTrackStatus,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => UserProfileModal(
        onNavigateToMyGrievances: onNavigateToMyGrievances,
        onNavigateToTrackStatus: onNavigateToTrackStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isGujarati = Provider.of<LanguageProvider>(context).isGujarati;
    final user = auth.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Govt Header strip
                  Container(
                    height: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.saffronPrimary,
                          Colors.white,
                          AppColors.emeraldPrimary,
                        ],
                      ),
                    ),
                  ),

                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isGujarati ? 'નાગરિક પ્રોફાઇલ' : 'Citizen Profile',
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  ),

                  // Avatar & details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: Column(
                      children: [
                        // Avatar Circle
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.navyDark, AppColors.navyMedium],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.saffronLight, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user.initials,
                              style: GoogleFonts.notoSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Name
                        Text(
                          user.name,
                          style: GoogleFonts.notoSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),

                        // Email
                        Text(
                          user.email,
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Status Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF6EE7B7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 14, color: AppColors.emeraldPrimary),
                              const SizedBox(width: 6),
                              Text(
                                isGujarati ? 'ચકાસાયેલ નાગરિક (Supabase)' : 'Verified Citizen (Supabase Auth)',
                                style: GoogleFonts.notoSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emeraldPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),

                        // Quick info tiles
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          title: isGujarati ? 'નાગરિક ID' : 'Citizen ID',
                          value: user.id,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.shield_outlined,
                          title: isGujarati ? 'ઓથેન્ટિકેશન પ્રદાતા' : 'Auth Provider',
                          value: user.provider.toUpperCase(),
                        ),

                        const SizedBox(height: 20),

                        // Navigation Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  onNavigateToMyGrievances?.call();
                                },
                                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                                label: Text(
                                  isGujarati ? 'મારી ફરિયાદો' : 'My Grievances',
                                  style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  onNavigateToTrackStatus?.call();
                                },
                                icon: const Icon(Icons.search, size: 16),
                                label: Text(
                                  isGujarati ? 'સ્થિતિ ટ્રેક કરો' : 'Track Status',
                                  style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(context, rootNavigator: true).pop();
                              await auth.logout();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isGujarati ? 'સફળતાપૂર્વક લોગ આઉટ થયા.' : 'Signed out safely.',
                                      style: GoogleFonts.notoSans(color: Colors.white),
                                    ),
                                    backgroundColor: AppColors.navyDark,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.logout, size: 16),
                            label: Text(
                              isGujarati ? 'સાઇન આઉટ કરો (Logout)' : 'Sign Out',
                              style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
