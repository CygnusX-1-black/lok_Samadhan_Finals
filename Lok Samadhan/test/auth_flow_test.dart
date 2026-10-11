import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahayak_vaani/providers/auth_provider.dart';
import 'package:sahayak_vaani/providers/grievance_provider.dart';
import 'package:sahayak_vaani/providers/language_provider.dart';
import 'package:sahayak_vaani/providers/location_provider.dart';
import 'package:sahayak_vaani/providers/voice_engine_provider.dart';
import 'package:sahayak_vaani/providers/chat_provider.dart';
import 'package:sahayak_vaani/providers/rewards_provider.dart';
import 'package:sahayak_vaani/screens/home_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestApp({AuthProvider? authProvider}) {
  return MultiProvider(
    providers: [
      if (authProvider != null)
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider)
      else
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<LocationProvider>(
        create: (_) => LocationProvider(),
      ),
      ChangeNotifierProvider<LanguageProvider>(
        create: (_) => LanguageProvider(),
      ),
      ChangeNotifierProvider<VoiceEngineProvider>(
        create: (_) => VoiceEngineProvider(),
      ),
      ChangeNotifierProvider<GrievanceProvider>(
        create: (_) => GrievanceProvider(),
      ),
      ChangeNotifierProvider<ChatProvider>(
        create: (_) => ChatProvider(),
      ),
      ChangeNotifierProvider<RewardsProvider>(
        create: (_) => RewardsProvider(),
      ),
    ],
    child: const MaterialApp(
      home: HomeNavigationScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GovtHeaderBanner displays Sign In button when unauthenticated', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Sign In and Citizen button are present
    expect(find.byTooltip('Sign In'), findsOneWidget);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    expect(find.byTooltip('Rewards'), findsOneWidget);
    expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
    expect(find.text('Citizen'), findsOneWidget);
  });

  testWidgets('Clicking Sign In opens AuthModal with Google and Email options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap Sign In icon button
    final signInButton = find.byTooltip('Sign In');
    await tester.tap(signInButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify AuthModal contents
    expect(find.text('Sign In to Lok Samadhan'), findsOneWidget);
    expect(find.text('Access your grievances, complaints and application status.'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    // Switch to Create Account mode
    await tester.tap(find.text('Create Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Create Account form fields
    expect(find.text('Create Citizen Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('Authenticated state displays user profile indicator and dropdown', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = AuthProvider();
    
    await tester.pumpWidget(createTestApp(authProvider: auth));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Sign in demo account
    await auth.signInWithEmail(email: 'srijan.verma@example.com', password: 'SrijanPassword123!');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify user name 'Srijan' appears in header
    expect(find.text('Srijan'), findsOneWidget);

    // Tap on profile indicator to open dropdown
    await tester.tap(find.text('Srijan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify dropdown items
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('My Grievances'), findsWidgets);
    expect(find.text('Track Status'), findsWidgets);
    expect(find.text('Logout'), findsOneWidget);

    // Tap Logout to test logout flow and dismiss popup
    await tester.tap(find.text('Logout'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    // Verify returned to unauthenticated Sign In state
    expect(find.byTooltip('Sign In'), findsOneWidget);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
  });
}
