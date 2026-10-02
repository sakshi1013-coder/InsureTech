import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:insurex_app/core/theme/app_theme.dart';
import 'package:insurex_app/features/officer/officer_shell.dart';
import 'package:insurex_app/features/officer/screens/officer_dashboard_screen.dart';
import 'package:insurex_app/features/officer/screens/officer_claims_screen.dart';
import 'package:insurex_app/features/officer/screens/officer_verification_screen.dart';
import 'package:insurex_app/features/officer/screens/officer_alerts_screen.dart';
import 'package:insurex_app/features/officer/screens/officer_profile_screen.dart';
import 'package:insurex_app/features/officer/screens/officer_claim_detail_screen.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'package:insurex_app/providers/auth_provider.dart';

void main() {
  testWidgets('Officer Portal Navigation & Workflow Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build OfficerShell wrapped in provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OfficerShell(initialIndex: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. VERIFY INITIAL STATE: DASHBOARD (Tab 0)
    expect(find.byType(OfficerDashboardScreen), findsOneWidget);
    expect(find.text('InsureX'), findsOneWidget);
    expect(find.text('OFFICER PORTAL / FIELD DESK'), findsOneWidget);

    // CRITICAL REQUIREMENT: VERIFY NO LOGOUT BUTTON IN DASHBOARD HEADER
    // The top-right header must NOT have a sign-out icon.
    // Dashboard header should contain ONLY notification bell & avatar initials.
    expect(find.byTooltip('Sign Out'), findsNothing);
    expect(find.byIcon(Icons.logout_outlined), findsNothing);
    expect(find.byTooltip('Officer Profile'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsWidgets);

    // 2. TEST: DASHBOARD -> CLAIMS (Tab 1)
    await tester.tap(find.text('Claims'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficerClaimsScreen), findsOneWidget);
    expect(find.text('Claims Roster'), findsOneWidget);
    expect(find.text('FIELD INVESTIGATION & REVIEWS'), findsOneWidget);

    // 3. TEST: CLAIMS -> CLAIM DETAILS
    // Tap the first claim card
    final firstClaim = find.byType(AppCard).first;
    await tester.tap(firstClaim);
    await tester.pumpAndSettle();

    // Detail screen opened
    expect(find.byType(OfficerClaimDetailScreen), findsOneWidget);
    // Detail screen has its own back button and does NOT show OfficerShell bottom bar
    final backBtn = find.byIcon(Icons.arrow_back_ios_new).first;
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Back in Claims
    expect(find.byType(OfficerClaimsScreen), findsOneWidget);

    // 4. TEST: CLAIMS -> VERIFICATION (Tab 2)
    await tester.tap(find.text('Verification'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficerVerificationScreen), findsOneWidget);
    expect(find.text('Verification Queue'), findsOneWidget);
    expect(find.text('FORENSIC EVIDENCE & DAMAGE TRIAGE'), findsOneWidget);

    // 5. TEST: VERIFICATION -> VERIFICATION DETAILS
    final verifyBtn = find.text('Verify & Inspect →').first;
    await tester.tap(verifyBtn);
    await tester.pumpAndSettle();

    expect(find.byType(OfficerClaimDetailScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
    await tester.pumpAndSettle();

    expect(find.byType(OfficerVerificationScreen), findsOneWidget);

    // 6. TEST: VERIFICATION -> ALERTS (Tab 3)
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficerAlertsScreen), findsOneWidget);
    expect(find.text('Alerts & Dispatch'), findsOneWidget);
    expect(find.text('New Claim Assigned'), findsOneWidget);

    // 7. TEST: ALERTS -> ALERT DETAILS
    await tester.tap(find.text('New Claim Assigned').first);
    await tester.pumpAndSettle();

    expect(find.byType(OfficerClaimDetailScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
    await tester.pumpAndSettle();

    expect(find.byType(OfficerAlertsScreen), findsOneWidget);

    // 8. TEST: OPEN PROFILE VIA HEADER AVATAR (Requirement 5)
    final avatarInAlerts = find.byTooltip('Officer Profile').first;
    await tester.tap(avatarInAlerts);
    await tester.pumpAndSettle();

    expect(find.byType(OfficerProfileScreen), findsOneWidget);
    expect(find.text('Marcus Vance'), findsOneWidget);
    expect(find.text('Senior Claims Adjuster'), findsWidgets);
    expect(find.text('Personnel Credentials'), findsOneWidget);
    expect(find.text('Employee ID'), findsOneWidget);
    expect(find.text('EMP-7721'), findsWidgets);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);

    // 9. TEST: PROFILE -> SIGN OUT MODAL
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Are you sure you want to end your active duty session and sign out of the Officer Portal?'), findsOneWidget);
    // Tap cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Pop back from profile to previous screen
    if (find.byIcon(Icons.arrow_back_ios_new).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
      await tester.pumpAndSettle();
    }

    // 10. Switch to Dashboard (Tab 0)
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficerDashboardScreen), findsOneWidget);
    expect(find.text('InsureX'), findsOneWidget);

    // 11. TEST: DASHBOARD HEADER NOTIFICATION -> ALERTS TAB
    final notifBtn = find.byIcon(Icons.notifications_outlined).first;
    await tester.tap(notifBtn);
    await tester.pumpAndSettle();

    expect(find.byType(OfficerAlertsScreen), findsOneWidget);

    // Return to Dashboard
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(OfficerDashboardScreen), findsOneWidget);

    // 12. TEST: DASHBOARD HEADER AVATAR -> PROFILE TAB
    final avatarBtn = find.byTooltip('Officer Profile');
    await tester.tap(avatarBtn);
    await tester.pumpAndSettle();

    expect(find.byType(OfficerProfileScreen), findsOneWidget);
    expect(find.text('Personnel Credentials'), findsOneWidget);

    // Return to Dashboard via back button
    if (find.byIcon(Icons.arrow_back_ios_new).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
      await tester.pumpAndSettle();
    }
    expect(find.byType(OfficerDashboardScreen), findsOneWidget);
  });
}
