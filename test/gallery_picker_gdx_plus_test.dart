import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_picker_gdx_plus/gallery_picker.dart';

void main() {
  group('Config', () {
    test('provides light and dark defaults', () {
      final light = Config();
      final dark = Config(mode: Mode.dark);

      expect(light.backgroundColor, Colors.white);
      expect(light.selectedMenuStyle.color, Colors.black);
      expect(dark.backgroundColor, const Color.fromARGB(255, 18, 27, 34));
      expect(dark.selectedMenuStyle.color, Colors.white);
    });

    test('applies explicit appearance values', () {
      const backgroundColor = Colors.amber;
      const appbarColor = Colors.blue;
      const textStyle = TextStyle(color: Colors.purple);

      final config = Config(
        backgroundColor: backgroundColor,
        appbarColor: appbarColor,
        textStyle: textStyle,
      );

      expect(config.backgroundColor, backgroundColor);
      expect(config.appbarColor, appbarColor);
      expect(config.textStyle, textStyle);
    });
  });
}
