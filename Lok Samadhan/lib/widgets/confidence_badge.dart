import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ConfidenceBadge extends StatelessWidget {
  final double score;
  final bool isHitlRequired;
  final bool showToCitizen;

  const ConfidenceBadge({
    super.key,
    required this.score,
    required this.isHitlRequired,
    this.showToCitizen = false,
  });

  @override
  Widget build(BuildContext context) {
    // If citizen-facing view and not flagged for HITL, hide backend score
    if (!showToCitizen && !isHitlRequired && score >= 0.85) {
      return const SizedBox.shrink();
    }

    final percentage = (score * 100).toStringAsFixed(0);
    final isLow = isHitlRequired || score < 0.85;

    final bgColor = isLow ? AppColors.purpleHitlBg : AppColors.emeraldBackground;
    final fgColor = isLow ? AppColors.purpleHitl : AppColors.emeraldPrimary;
    final borderColor = isLow ? AppColors.purpleHitl.withOpacity(0.3) : AppColors.emeraldPrimary.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLow ? Icons.psychology_alt_outlined : Icons.auto_awesome,
            size: 13,
            color: fgColor,
          ),
          const SizedBox(width: 4),
          Text(
            isLow ? 'HITL Review Queue' : 'AI Verified ($percentage%)',
            style: GoogleFonts.notoSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
