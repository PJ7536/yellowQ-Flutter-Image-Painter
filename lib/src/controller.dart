import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../image_painter.dart';
import '_signature_painter.dart';

class ImagePainterController extends ChangeNotifier {
  // Properties
  late double _strokeWidth;
  late Color _color;
  late PaintMode _mode;
  late String _text;
  late bool _fill;
  late ui.Image? _image;
  Rect _rect = Rect.zero;

  final List<Offset?> _offsets = [];
  final List<PaintInfo> _paintHistory = [];

  Offset? _start, _end;
  int _strokeMultiplier = 1;
  bool _paintInProgress = false;
  bool _isSignature = false;

  // Getters
  ui.Image? get image => _image;

  Paint get brush =>
      Paint()
        ..color = _color
        ..strokeWidth = _strokeWidth * _strokeMultiplier
        ..style = shouldFill ? PaintingStyle.fill : PaintingStyle.stroke;

  PaintMode get mode => _mode;

  double get strokeWidth => _strokeWidth;

  double get scaledStrokeWidth => _strokeWidth * _strokeMultiplier;

  bool get busy => _paintInProgress;

  bool get fill => _fill;

  Color get color => _color;

  List<PaintInfo> get paintHistory => _paintHistory;

  List<Offset?> get offsets => _offsets;

  Offset? get start => _start;

  Offset? get end => _end;

  bool get onTextUpdateMode =>
      _mode == PaintMode.text && _paintHistory
          .where((element) => element.mode == PaintMode.text)
          .isNotEmpty;

  double get rotation => _rotation;

  Offset get rotateOffset => _rotateOffset;

  bool get flipHorizontal => _flipHorizontal;

  double _rotation = 0.0;
  Offset _rotateOffset = const Offset(0, 0);

  bool _flipHorizontal = false;

  ImagePainterController({
    double strokeWidth = 4.0,
    Color color = Colors.red,
    PaintMode mode = PaintMode.freeStyle,
    String text = '',
    bool fill = false,
  }) {
    _strokeWidth = strokeWidth;
    _color = color;
    _mode = mode;
    _text = text;
    _fill = fill;
  }

  // Setters
  void setImage(ui.Image image) {
    _image = image;
    notifyListeners();
  }

  void setRect(Size size, bool isSig) {
    _rect = Rect.fromLTWH(0, 0, size.width, size.height);
    _isSignature = isSig;
    notifyListeners();
  }

  void addPaintInfo(PaintInfo paintInfo) {
    _paintHistory.add(paintInfo);
    notifyListeners();
  }

  void undo() {
    if (_rotation != 0.0) rotateImage(-(pi / 2));
    if (_flipHorizontal) _flipHorizontal = false;
    if (_paintHistory.isNotEmpty) {
      _paintHistory.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _rotation = 0;
    _flipHorizontal = false;
    if (_paintHistory.isNotEmpty) {
      _paintHistory.clear();
      notifyListeners();
    }
  }

  void rotateImage(double angle) {
    _rotation += angle;
    final width = image?.width ?? 1;
    final height = image?.height ?? 0;
    _rotateOffset = Offset(width / 2, height / 2);
    addPaintInfo(PaintInfo(mode: PaintMode.rotate, offsets: [_rotateOffset], color: Colors.black, strokeWidth: 0));
  }

  void flipImage() {
    _flipHorizontal = !flipHorizontal;
    notifyListeners();
  }

  void setStrokeWidth(double val) {
    _strokeWidth = val;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  void setMode(PaintMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setText(String val) {
    _text = val;
    notifyListeners();
  }

  void addOffsets(Offset? offset) {
    _offsets.add(offset);
    notifyListeners();
  }

  void setStart(Offset? offset) {
    _start = offset;
    notifyListeners();
  }

  void setEnd(Offset? offset) {
    _end = offset;
    notifyListeners();
  }

  void resetStartAndEnd() {
    _start = null;
    _end = null;
    notifyListeners();
  }

  void update({
    double? strokeWidth,
    Color? color,
    bool? fill,
    PaintMode? mode,
    String? text,
    int? strokeMultiplier,
  }) {
    _strokeWidth = strokeWidth ?? _strokeWidth;
    _color = color ?? _color;
    _fill = fill ?? _fill;
    _mode = mode ?? _mode;
    _text = text ?? _text;
    _strokeMultiplier = strokeMultiplier ?? _strokeMultiplier;
    notifyListeners();
  }

  void setInProgress(bool val) {
    _paintInProgress = val;
    notifyListeners();
  }

  bool get shouldFill {
    if (mode == PaintMode.circle || mode == PaintMode.rect) {
      return _fill;
    } else {
      return false;
    }
  }


  // Image rendering and exporting
  Future<Uint8List?> _renderImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = DrawImage(controller: this);
    final size = Size(_image!.width.toDouble(), _image!.height.toDouble());
    painter.paint(canvas, size);
    final _convertedImage = await recorder.endRecording().toImage(size.width.floor(), size.height.floor());
    final byteData = await _convertedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List?> _renderSignature() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    SignaturePainter painter = SignaturePainter(controller: this, backgroundColor: Colors.blue);
    Size size = Size(_rect.width, _rect.height);
    painter.paint(canvas, size);
    final _convertedImage = await recorder.endRecording().toImage(size.width.floor(), size.height.floor());
    final byteData = await _convertedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List?> exportImage() {
    if (_isSignature) {
      return _renderSignature();
    } else {
      return _renderImage();
    }
  }
}

extension ControllerExt on ImagePainterController {
  bool canFill() {
    return mode == PaintMode.circle || mode == PaintMode.rect;
  }
}

