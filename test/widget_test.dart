import 'package:flutter_test/flutter_test.dart';

import 'package:raccontamela/main.dart';

void main() {
  testWidgets('Raccontamela starts', (tester) async {
    await tester.pumpWidget(const RaccontamelaApp());
    expect(find.text('Raccontamela'), findsWidgets);
  });
}
