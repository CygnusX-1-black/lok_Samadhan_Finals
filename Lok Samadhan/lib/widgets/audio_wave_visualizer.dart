import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AudioWaveVisualizer extends StatelessWidget {
  final List<double> amplitudes;
  final bool isRecording;
  final Color? barColor;
  final double height;

  const AudioWaveVisualizer({
    super.key,
    required this.amplitudes,
    this.isRecording = false,
    this.barColor,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = barColor ?? (isRecording ? AppColors.saffronPrimary : AppColors.navyMedium);

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(amplitudes.length, (index) {
          final amp = amplitudes[index].clamp(0.05, 1.0);
          final barHeight = height * amp;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 3.5,
            height: barHeight,
            decoration: BoxDecoration(
              color: activeColor.withOpacity(isRecording ? 0.9 : 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
