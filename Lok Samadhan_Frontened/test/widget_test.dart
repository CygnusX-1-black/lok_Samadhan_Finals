import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahayak_vaani/main.dart';
import 'package:sahayak_vaani/providers/language_provider.dart';
import 'package:sahayak_vaani/screens/home_navigation_screen.dart';

void main() {
  testWidgets('Lok Samadhan app launch test', (WidgetTester tester) async {
    // Build Lok Samadhan App and trigger a frame.
    await tester.pumpWidget(const LokSamadhanApp());

    // Verify that Lok Samadhan header text renders.
    expect(find.text('लोक समाधान'), findsOneWidget);

    // Verify AI Chat bottom navigation item exists
    expect(find.text('AI Chat'), findsOneWidget);

    // Tap on AI Chat tab
    await tester.tap(find.text('AI Chat'));
    await tester.pumpAndSettle();

    // Verify that AI Chat header and assistant render
    expect(find.text('Lok Samadhan AI Sahayak'), findsOneWidget);
  });

  testWidgets('AI Chat grievance lodging flow test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LokSamadhanApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap on AI Chat tab
    await tester.tap(find.text('AI Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify initial welcome quick reply chips appear
    expect(find.text('💧 Drinking Water Handpump (પીવાનું પાણી)'), findsOneWidget);

    // Tap on the quick chip
    await tester.tap(find.text('💧 Drinking Water Handpump (પીવાનું પાણી)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    // Verify that the Draft Grievance Card renders with Confirm button
    expect(find.text('Confirm & Lodge'), findsOneWidget);
    await tester.ensureVisible(find.text('Confirm & Lodge'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap on Confirm & Lodge
    await tester.tap(find.text('Confirm & Lodge'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    // Ensure success card is visible
    await tester.ensureVisible(find.text('Grievance Registered with GPS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify that the grievance was successfully registered with GPS
    expect(find.text('Grievance Registered with GPS'), findsOneWidget);
    expect(find.text('Track Status'), findsWidgets);
  });

  testWidgets('Gujarati language switching and dialect selection test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LokSamadhanApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify LanguageProvider has Gujarati in available dialects
    final langProvider = Provider.of<LanguageProvider>(
      tester.element(find.byType(HomeNavigationScreen)),
      listen: false,
    );
    expect(langProvider.isGujarati, isFalse);
    expect(LanguageProvider.availableDialects.any((d) => d.id == 'gujarati'), isTrue);

    // Switch to Gujarati
    langProvider.setDialectById('gujarati');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify state and reactive UI
    expect(langProvider.isGujarati, isTrue);
    expect(find.text('લોક સમાધાન'), findsOneWidget);
    expect(find.text('બોલીને તમારી ફરિયાદ નોંધાવો'), findsOneWidget);
    expect(find.text('૧. તમારી ભાષા / બોલી પસંદ કરો (Select Dialect):'), findsOneWidget);
  });
}
