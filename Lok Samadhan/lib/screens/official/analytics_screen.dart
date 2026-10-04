import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Text(
            'विभाग एवं जिला प्रदर्शन विश्लेषण (Analytics & Insights)',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'SLA Compliance, Category Distribution & Voice AI Performance Metrics',
            style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Core Metrics Summary Row
          Row(
            children: [
              _buildMetricTile('Auto-Routing Accuracy', '93.4%', 'Target >90%', Icons.precision_manufacturing, AppColors.emeraldPrimary),
              const SizedBox(width: 8),
              _buildMetricTile('Avg Filing Time', '1.4 min', 'Target < 2 min', Icons.timer_outlined, AppColors.saffronPrimary),
              const SizedBox(width: 8),
              _buildMetricTile('HITL Fallback Rate', '6.6%', 'Low-confidence AI', Icons.psychology, AppColors.purpleHitl),
            ],
          ),
          const SizedBox(height: 16),

          // Department Category Breakdown Bar Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category Distribution (विभाग अनुसार)',
                        style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const Icon(Icons.bar_chart, color: AppColors.navyMedium, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 10,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const labels = ['Water', 'Elec', 'PWD', 'Ration', 'Health', 'Pensions'];
                                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(labels[value.toInt()], style: GoogleFonts.notoSans(fontSize: 10.5, fontWeight: FontWeight.w600)),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _makeBarGroup(0, 8, AppColors.navyMedium),
                          _makeBarGroup(1, 6, AppColors.saffronPrimary),
                          _makeBarGroup(2, 4, AppColors.emeraldPrimary),
                          _makeBarGroup(3, 5, Colors.purple),
                          _makeBarGroup(4, 3, Colors.teal),
                          _makeBarGroup(5, 7, Colors.amber.shade800),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // SLA Compliance & Resolution Rate Pie Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SLA Resolution Status (समय-सीमा अनुपालन)',
                    style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 32,
                            sections: [
                              PieChartSectionData(
                                color: AppColors.emeraldPrimary,
                                value: 65,
                                title: '65%',
                                radius: 36,
                                titleStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: AppColors.amberOrange,
                                value: 22,
                                title: '22%',
                                radius: 36,
                                titleStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: AppColors.warningRed,
                                value: 13,
                                title: '13%',
                                radius: 36,
                                titleStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem('Within SLA (Resolved)', '65%', AppColors.emeraldPrimary),
                            const SizedBox(height: 8),
                            _buildLegendItem('In Progress (Active)', '22%', AppColors.amberOrange),
                            const SizedBox(height: 8),
                            _buildLegendItem('SLA Overdue (Escalated)', '13%', AppColors.warningRed),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Regional Dialect Adoption Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Regional Dialect Usage (બોલી / ભાષા વપરાશ)',
                    style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildDialectProgressBar('Gujarati (Gujarat)', 0.22, '22% Calls', const Color(0xFF0D9488)),
                  const SizedBox(height: 10),
                  _buildDialectProgressBar('Bhojpuri (Bihar/East UP)', 0.32, '32% Calls', AppColors.saffronPrimary),
                  const SizedBox(height: 10),
                  _buildDialectProgressBar('Marwari (Rajasthan)', 0.20, '20% Calls', AppColors.navyMedium),
                  const SizedBox(height: 10),
                  _buildDialectProgressBar('Santali (Jharkhand/Odisha)', 0.14, '14% Calls', AppColors.purpleHitl),
                  const SizedBox(height: 10),
                  _buildDialectProgressBar('Bengali & Tamil', 0.12, '12% Calls', AppColors.emeraldPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, String sub, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(val, style: GoogleFonts.notoSans(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
            Text(title, style: GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(sub, style: GoogleFonts.notoSans(fontSize: 9.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: GoogleFonts.notoSans(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ),
        Text(value, style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildDialectProgressBar(String dialect, double factor, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dialect, style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(label, style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: factor,
          backgroundColor: AppColors.surfaceSubtle,
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
