import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/grievance.dart';
import '../theme/app_colors.dart';

class SlaCountdownBadge extends StatelessWidget {
  final Grievance grievance;

  const SlaCountdownBadge({
    super.key,
    required this.grievance,
  });

  @override
  Widget build(BuildContext context) {
    if (grievance.status == GrievanceStatus.resolved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.emeraldBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.emeraldPrimary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 13, color: AppColors.emeraldPrimary),
            const SizedBox(width: 4),
            Text(
              'SLA Met (Resolved)',
              style: GoogleFonts.notoSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.emeraldPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (grievance.isSlaBreached) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warningRedBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.warningRed.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.warningRed),
            const SizedBox(width: 4),
            Text(
              'OVERDUE • Escalation L${grievance.escalationLevel > 0 ? grievance.escalationLevel : 1}',
              style: GoogleFonts.notoSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.warningRed,
              ),
            ),
          ],
        ),
      );
    }

    final duration = grievance.remainingSlaDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    final isWarning = hours < 12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.amberOrangeBg : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isWarning ? AppColors.amberOrange.withOpacity(0.4) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 13,
            color: isWarning ? AppColors.amberOrange : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            'SLA: ${hours}h ${minutes}m left',
            style: GoogleFonts.notoSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isWarning ? AppColors.amberOrange : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
