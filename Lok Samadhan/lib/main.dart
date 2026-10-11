import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/grievance_provider.dart';
import 'providers/language_provider.dart';
import 'providers/location_provider.dart';
import 'providers/rewards_provider.dart';
import 'providers/voice_engine_provider.dart';
import 'screens/home_navigation_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();
  runApp(const LokSamadhanApp());
}

class LokSamadhanApp extends StatelessWidget {
  const LokSamadhanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => VoiceEngineProvider()),
        ChangeNotifierProvider(create: (_) => GrievanceProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => RewardsProvider()),
      ],
      child: MaterialApp(
        title: 'Lok Samadhan - Voice Grievance Bot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeNavigationScreen(),
      ),
    );
  }
}

// Backwards compatibility alias
typedef SahayakVaaniApp = LokSamadhanApp;
