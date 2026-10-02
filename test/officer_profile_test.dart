import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:insurex_app/providers/auth_provider.dart';
import 'package:insurex_app/features/officer/screens/officer_profile_screen.dart';

void main() {
  testWidgets('OfficerProfileScreen renders credentials and sign out button', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: OfficerProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Officer Profile'), findsOneWidget);
    expect(find.text('Personnel Credentials'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsWidgets);
  });
}
