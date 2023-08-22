import 'package:flame/components.dart';

class MyTextBox extends TextBoxComponent {
  MyTextBox({text, position, anchor})
      : super(
          text: text,
          position: position,
          anchor: anchor,
          boxConfig: TextBoxConfig(timePerChar: 0.05),
        );
}
