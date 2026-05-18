import 'package:flutter/widgets.dart';

/// Logical width/height → decode size in pixels for [Image.network] cache dims.
int posterDecodePixels(BuildContext context, double logicalSize) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalSize * dpr).round().clamp(48, 1200);
}
