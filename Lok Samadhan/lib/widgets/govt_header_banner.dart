import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../providers/grievance_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import 'auth/auth_modal.dart';
import 'auth/user_profile_modal.dart';

class GovtHeaderBanner extends StatelessWidget implements PreferredSizeWidget {
  final bool showPersonaToggle;
  final Function(int tabIndex)? onSelectCitizenTab;

  const GovtHeaderBanner({
    super.key,
    this.showPersonaToggle = true,
    this.onSelectCitizenTab,
  });

  @override
  Size get preferredSize => const Size.fromHeight(82);

  @override
  Widget build(BuildContext context) {
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentPersona = grievanceProvider.currentPersona;
    final isGujarati = languageProvider.isGujarati;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0B3D2E), // Deep India Forest / Emerald Green
            Color(0xFF14532D), // Rich Government Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.saffronPrimary,
            width: 2.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Official State Emblem of India (Ashoka Lion Capital Statue)
              Container(
                width: 46,
                height: 54,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.saffronLight.withOpacity(0.8), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/emblem_india.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance,
                      color: AppColors.saffronPrimary,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle with Gujarati adaptation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isGujarati ? 'લોક સમાધાન' : 'लोक समाधान',
                      style: GoogleFonts.notoSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: grievanceProvider.isBackendConnected ? Colors.greenAccent : const Color(0xFFFFB74D),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            grievanceProvider.isBackendConnected
                                ? (isGujarati ? 'લાઇવ કનેક્ટેડ (Supabase)' : 'Live Connected (Supabase)')
                                : (isGujarati ? 'સ્થાનિક મોડ (Local)' : 'Lok Samadhan Portal'),
                            style: GoogleFonts.notoSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: grievanceProvider.isBackendConnected ? Colors.greenAccent : Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Persona Switcher Button (👤 Citizen / 👮 Officer)
              if (showPersonaToggle)
                InkWell(
                  onTap: () {
                    final nextPersona = currentPersona == UserPersona.citizen
                        ? UserPersona.governmentOfficial
                        : UserPersona.citizen;
                    grievanceProvider.switchPersona(nextPersona);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: currentPersona == UserPersona.citizen
                          ? AppColors.saffronPrimary.withOpacity(0.95)
                          : const Color(0xFF0284C7).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          currentPersona == UserPersona.citizen
                              ? Icons.person_outline
                              : Icons.admin_panel_settings_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentPersona == UserPersona.citizen
                              ? (isGujarati ? 'નાગરિક' : 'Citizen')
                              : (isGujarati ? 'અધિકારી' : 'Officer'),
                          style: GoogleFonts.notoSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Sign In Button OR Authenticated User Indicator (Immediately to the right of Citizen button)
              const SizedBox(width: 6),
              if (!authProvider.isAuthenticated)
                InkWell(
                  onTap: () => AuthModal.show(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.saffronLight.withOpacity(0.9),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          color: AppColors.saffronLight,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isGujarati ? 'સાઇન ઇન' : 'Sign In',
                          style: GoogleFonts.notoSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'User Account Menu',
                  color: AppColors.navyDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onSelected: (value) async {
                    if (value == 'profile') {
                      UserProfileModal.show(
                        context,
                        onNavigateToMyGrievances: () => onSelectCitizenTab?.call(4),
                        onNavigateToTrackStatus: () => onSelectCitizenTab?.call(3),
                      );
                    } else if (value == 'grievances') {
                      onSelectCitizenTab?.call(4);
                    } else if (value == 'track') {
                      onSelectCitizenTab?.call(3);
                    } else if (value == 'logout') {
                      await authProvider.logout();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isGujarati ? 'સફળતાપૂર્વક લોગ આઉટ થયા.' : 'Signed out safely.',
                              style: GoogleFonts.notoSans(color: Colors.white),
                            ),
                            backgroundColor: AppColors.navyDark,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    // User Info Header
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.currentUser?.name ?? 'Citizen',
                              style: GoogleFonts.notoSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              authProvider.currentUser?.email ?? '',
                              style: GoogleFonts.notoSans(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldPrimary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.emeraldLight, width: 0.8),
                              ),
                              child: Text(
                                'Verified Citizen (Supabase)',
                                style: GoogleFonts.notoSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            isGujarati ? 'મારી પ્રોફાઇલ (My Profile)' : 'My Profile',
                            style: GoogleFonts.notoSans(fontSize: 12.5, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'grievances',
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            isGujarati ? 'મારી ફરિયાદો (My Grievances)' : 'My Grievances',
                            style: GoogleFonts.notoSans(fontSize: 12.5, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'track',
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            isGujarati ? 'સ્થિતિ ટ્રેક કરો (Track Status)' : 'Track Status',
                            style: GoogleFonts.notoSans(fontSize: 12.5, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout, size: 16, color: Color(0xFFFCA5A5)),
                          const SizedBox(width: 8),
                          Text(
                            isGujarati ? 'સાઇન આઉટ કરો (Logout)' : 'Logout',
                            style: GoogleFonts.notoSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFCA5A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldPrimary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          authProvider.currentUser?.name.split(' ')[0] ?? 'User',
                          style: GoogleFonts.notoSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

