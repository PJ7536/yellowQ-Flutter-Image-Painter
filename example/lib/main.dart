import 'package:flutter/material.dart';
import 'package:image_painter_example/mobile_example.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Painter Example',
      theme: ThemeData(
        brightness: Brightness.dark
      ),
      home: ImagePainterExample(),
    );
  }
}

class ImagePainterExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MobileExample();
  }
}
