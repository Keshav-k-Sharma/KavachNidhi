import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';

void main() {
  testWidgets('renders login screen content', (WidgetTester tester) async {
    await tester.pumpWidget(const KavachNidhiApp());

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('REQUEST OTP'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
  });

  testWidgets('navigates from login to signup', (WidgetTester tester) async {
    await tester.pumpWidget(const KavachNidhiApp());

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Join'), findsOneWidget);
    expect(find.textContaining('KavachNidhi'), findsWidgets);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
  });

  testWidgets('navigates from signup back to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KavachNidhiApp());

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    final Finder loginLink = find.text('Log in');
    await tester.ensureVisible(loginLink);
    await tester.pumpAndSettle();
    await tester.tap(loginLink);
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
