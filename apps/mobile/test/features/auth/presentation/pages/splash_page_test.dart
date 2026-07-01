import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/splash_page.dart';

void main() {
  group('SplashPage Widget Tests', () {
    testWidgets('renders Scaffold with specific background color',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashPage()));

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.backgroundColor, const Color(0xFF111827));
    });

    testWidgets('renders Image.asset with correct path and size',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashPage()));

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final image = tester.widget<Image>(imageFinder);
      final assetImage = image.image as AssetImage;
      expect(assetImage.assetName, 'assets/icons/app_icon.png');
      expect(image.width, 144);
      expect(image.height, 144);
    });
  });
}
