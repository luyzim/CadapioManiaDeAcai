import 'package:flutter_test/flutter_test.dart';
import 'package:mania_de_acai/app/mania_de_acai_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows the login screen by default', (WidgetTester tester) async {
    await tester.pumpWidget(const ManiaDeAcaiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('ManiaDeAcai'), findsWidgets);
    expect(find.text('Sobre o projeto'), findsOneWidget);
  });
}
