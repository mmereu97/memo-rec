import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:memo_rec/main.dart';
import 'package:memo_rec/services/settings_service.dart';

void main() {
  testWidgets('MemoRec starts on the recording screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();

    await tester.pumpWidget(const MemoRecApp());
    await tester.pump();

    expect(find.text('MEMO REC'), findsOneWidget);
    expect(find.text('ÎNREGISTREAZĂ'), findsOneWidget);
  });
}
