import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../models/grievance.dart';
import '../../providers/grievance_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/backend_status_banner.dart';
import '../../widgets/complaint_card.dart';
import 'grievance_detail_screen.dart';

class DepartmentDashboardScreen extends StatelessWidget {
  const DepartmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
    final filteredList = grievanceProvider.filteredGrievances;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Backend Connectivity Indicator & Quick Sync
          const BackendStatusBanner(),

          // Responsive KPI Metric Grid Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildKpiCard('Total Incoming', '${grievanceProvider.totalCount}', Icons.inbox, AppColors.navyMedium),
                const SizedBox(width: 8),
                _buildKpiCard('In Progress', '${grievanceProvider.inProgressCount}', Icons.engineering, AppColors.amberOrange),
                const SizedBox(width: 8),
                _buildKpiCard('SLA Overdue', '${grievanceProvider.slaBreachedCount}', Icons.warning_amber, AppColors.warningRed),
                const SizedBox(width: 8),
                _buildKpiCard('Resolved', '${grievanceProvider.resolvedCount}', Icons.check_circle, AppColors.emeraldPrimary),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search & Filter Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by ID, location, dialect...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => grievanceProvider.setSearchQuery(val),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Overdue SLA'),
                selected: grievanceProvider.filterOnlySlaBreached,
                selectedColor: AppColors.warningRedBg,
                side: BorderSide(
                  color: grievanceProvider.filterOnlySlaBreached ? AppColors.warningRed : AppColors.cardBorder,
                ),
                onSelected: (_) => grievanceProvider.toggleFilterSlaBreached(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Department Taxonomy Filter Chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('All Depts'),
                    selected: grievanceProvider.filterDepartment == null,
                    onSelected: (val) => grievanceProvider.setFilterDepartment(null),
                  ),
                ),
                ...DepartmentInfo.allDepartments.map((dept) {
                  final isSelected = grievanceProvider.filterDepartment == dept.category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(dept.icon, size: 14, color: isSelected ? Colors.white : dept.color),
                      label: Text(dept.code),
                      selected: isSelected,
                      selectedColor: dept.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 11.5,
                      ),
                      onSelected: (val) {
                        grievanceProvider.setFilterDepartment(val ? dept.category : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Grievance Triage List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No grievances match the selected filter.',
                          style: GoogleFonts.notoSans(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final g = filteredList[index];
                      return ComplaintCard(
                        grievance: g,
                        showConfidence: true, // Shown to department officer!
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => GrievanceDetailScreen(grievanceId: g.id),
                            ),
                          );
                        },
                        trailingAction: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: const Text('Action', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            _showQuickActionDialog(context, g);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showQuickActionDialog(BuildContext context, Grievance g) {
    final grievanceProvider = Provider.of<GrievanceProvider>(context, listen: false);
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Status: ${g.id}', style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Status: ${g.status.labelEn}', style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Official Action Note / Remarks',
                hintText: 'e.g. Maintenance team dispatched to site.',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyMedium),
                  child: const Text('Under Investigation'),
                  onPressed: () {
                    grievanceProvider.updateGrievanceStatus(
                      grievanceId: g.id,
                      newStatus: GrievanceStatus.underReview,
                      officialNote: noteController.text,
                    );
                    Navigator.pop(ctx);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                  child: const Text('In Progress'),
                  onPressed: () {
                    grievanceProvider.updateGrievanceStatus(
                      grievanceId: g.id,
                      newStatus: GrievanceStatus.inProgress,
                      officialNote: noteController.text,
                    );
                    Navigator.pop(ctx);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldPrimary),
                  child: const Text('Resolve & Close'),
                  onPressed: () {
                    grievanceProvider.updateGrievanceStatus(
                      grievanceId: g.id,
                      newStatus: GrievanceStatus.resolved,
                      officialNote: noteController.text.isEmpty ? 'Issue verified and repaired on site.' : noteController.text,
                    );
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
