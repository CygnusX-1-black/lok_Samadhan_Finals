import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_role.dart';
import '../providers/grievance_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/govt_header_banner.dart';

import 'citizen/ai_photo_lodge_screen.dart';
import 'citizen/chat_lodge_screen.dart';
import 'citizen/my_grievances_screen.dart';
import 'citizen/track_grievance_screen.dart';
import 'citizen/voice_lodge_screen.dart';

import 'official/analytics_screen.dart';
import 'official/department_dashboard_screen.dart';
import 'official/hitl_queue_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _citizenTabIndex = 0;
  int _officialTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
    final currentPersona = grievanceProvider.currentPersona;
    final hitlPendingCount = grievanceProvider.hitlCount;

    return Scaffold(
      appBar: GovtHeaderBanner(
        onSelectCitizenTab: (index) {
          if (currentPersona != UserPersona.citizen) {
            grievanceProvider.switchPersona(UserPersona.citizen);
          }
          setState(() => _citizenTabIndex = index);
        },
      ),
      body: SafeArea(
        child: currentPersona == UserPersona.citizen
            ? _buildCitizenBody()
            : _buildOfficialBody(),
      ),
      bottomNavigationBar: currentPersona == UserPersona.citizen
          ? _buildCitizenBottomNav()
          : _buildOfficialBottomNav(hitlPendingCount),
    );
  }

  Widget _buildCitizenBody() {
    switch (_citizenTabIndex) {
      case 0:
        return const VoiceLodgeScreen();
      case 1:
        return const AiPhotoLodgeScreen();
      case 2:
        return ChatLodgeScreen(
          onTrackGrievance: (id) {
            setState(() => _citizenTabIndex = 3);
            Provider.of<GrievanceProvider>(context, listen: false).setSearchQuery(id);
          },
          onNavigateToMyGrievances: () {
            setState(() => _citizenTabIndex = 4);
          },
        );
      case 3:
        return const TrackGrievanceScreen();
      case 4:
        return const MyGrievancesScreen();
      default:
        return const VoiceLodgeScreen();
    }
  }

  Widget _buildOfficialBody() {
    switch (_officialTabIndex) {
      case 0:
        return const DepartmentDashboardScreen();
      case 1:
        return const HitlQueueScreen();
      case 2:
        return const AnalyticsScreen();
      default:
        return const DepartmentDashboardScreen();
    }
  }

  Widget _buildCitizenBottomNav() {
    return BottomNavigationBar(
      currentIndex: _citizenTabIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.navyDark,
      selectedItemColor: AppColors.saffronLight,
      unselectedItemColor: Colors.white60,
      selectedLabelStyle: GoogleFonts.notoSans(fontSize: 10.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.notoSans(fontSize: 10),
      onTap: (index) => setState(() => _citizenTabIndex = index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.mic),
          activeIcon: Icon(Icons.mic, color: AppColors.saffronLight),
          label: 'Voice Lodge',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt_outlined),
          activeIcon: Icon(Icons.camera_alt, color: AppColors.saffronLight),
          label: 'AI Photo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_outlined),
          activeIcon: Icon(Icons.chat, color: AppColors.saffronLight),
          label: 'AI Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search, color: AppColors.saffronLight),
          label: 'Track Status',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long, color: AppColors.saffronLight),
          label: 'My Grievances',
        ),
      ],
    );
  }

  Widget _buildOfficialBottomNav(int hitlPendingCount) {
    return BottomNavigationBar(
      currentIndex: _officialTabIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.navyDark,
      selectedItemColor: AppColors.saffronLight,
      unselectedItemColor: Colors.white60,
      selectedLabelStyle: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.notoSans(fontSize: 10.5),
      onTap: (index) => setState(() => _officialTabIndex = index),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard, color: AppColors.saffronLight),
          label: 'Dept Triage',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('$hitlPendingCount'),
            isLabelVisible: hitlPendingCount > 0,
            backgroundColor: AppColors.purpleHitl,
            child: const Icon(Icons.psychology_outlined),
          ),
          activeIcon: Badge(
            label: Text('$hitlPendingCount'),
            isLabelVisible: hitlPendingCount > 0,
            backgroundColor: AppColors.purpleHitl,
            child: const Icon(Icons.psychology, color: AppColors.saffronLight),
          ),
          label: 'HITL Queue',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics, color: AppColors.saffronLight),
          label: 'Analytics',
        ),
      ],
    );
  }
}
