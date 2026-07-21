import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_picker_gdx_plus_example/main.dart';

void main() {
  testWidgets('example application renders', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Gallery Picker'), findsOneWidget);
    expect(find.text('These are your selected medias'), findsOneWidget);
  });
}
