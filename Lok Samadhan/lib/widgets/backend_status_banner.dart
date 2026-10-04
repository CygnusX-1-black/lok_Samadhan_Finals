import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/grievance_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class BackendStatusBanner extends StatelessWidget {
  final bool compact;

  const BackendStatusBanner({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GrievanceProvider>(context);
    final isConnected = provider.isBackendConnected;
    final isLoading = provider.isLoadingBackend;

    if (compact) {
      return InkWell(
        onTap: () => showBackendConfigDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isConnected
                ? const Color(0xFF059669).withOpacity(0.15)
                : const Color(0xFFDC2626).withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isConnected ? const Color(0xFF059669) : const Color(0xFFDC2626),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isConnected ? 'Backend Active' : 'Offline Mode',
                style: GoogleFonts.notoSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isConnected ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isConnected ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            child: Icon(
              isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      isConnected
                          ? 'Connected to Backend (Node.js + Supabase)'
                          : 'Backend Disconnected (Using Local Fallback)',
                      style: GoogleFonts.notoSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isConnected ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                    if (isConnected && provider.databaseMode.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          provider.databaseMode.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'API: ${provider.activeBackendUrl}',
                  style: GoogleFonts.firaCode(
                    fontSize: 10.5,
                    color: isConnected ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Sync Button
          IconButton(
            tooltip: 'Sync with Backend',
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 18),
            color: isConnected ? const Color(0xFF059669) : const Color(0xFFDC2626),
            onPressed: isLoading ? null : () => provider.refreshAll(),
          ),
          // Configure Button
          IconButton(
            tooltip: 'Configure Backend URL',
            icon: const Icon(Icons.settings_outlined, size: 18),
            color: AppColors.textSecondary,
            onPressed: () => showBackendConfigDialog(context),
          ),
        ],
      ),
    );
  }

  static void showBackendConfigDialog(BuildContext context) {
    final textController = TextEditingController(text: ApiConfig.baseUrl);
    bool testing = false;
    String? testResult;
    bool testSuccess = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.settings_input_component, color: AppColors.emeraldPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Backend API Settings',
                    style: GoogleFonts.notoSans(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Specify the Lok Samadhan Node.js backend URL to synchronize grievances and AI classifications in real time.',
                      style: GoogleFonts.notoSans(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        labelText: 'Backend Base URL',
                        hintText: 'http://localhost:5000/api',
                        prefixIcon: Icon(Icons.link, size: 20),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: GoogleFonts.firaCode(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.wifi, size: 14),
                          label: const Text('Wi-Fi (10.90.141.134)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              textController.text = 'http://10.90.141.134:5000/api';
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.usb, size: 14),
                          label: const Text('USB adb reverse', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              textController.text = 'http://localhost:5000/api';
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              textController.text = 'http://10.0.2.2:5000/api';
                            });
                          },
                        ),
                      ],
                    ),
                    if (testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: testSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: testSuccess ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              testSuccess ? Icons.check_circle : Icons.error_outline,
                              size: 16,
                              color: testSuccess ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                testResult!,
                                style: GoogleFonts.notoSans(
                                  fontSize: 11.5,
                                  color: testSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: testing
                      ? null
                      : () async {
                          setState(() {
                            testing = true;
                            testResult = 'Testing connection...';
                            testSuccess = false;
                          });

                          ApiConfig.setCustomBaseUrl(textController.text);
                          final res = await ApiService().checkHealth();

                          setState(() {
                            testing = false;
                            testSuccess = res.isConnected;
                            testResult = res.isConnected
                                ? 'Connected! Database: ${res.databaseMode ?? "active"}'
                                : 'Failed: ${res.error ?? "Server unreachable"}';
                          });
                        },
                  child: testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test Connection'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    ApiConfig.setCustomBaseUrl(textController.text);
                    final grievanceProvider = Provider.of<GrievanceProvider>(context, listen: false);
                    await grievanceProvider.refreshAll();
                    if (context.mounted) {
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated Backend URL to: ${ApiConfig.baseUrl}'),
                          backgroundColor: AppColors.emeraldPrimary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text('Save & Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
