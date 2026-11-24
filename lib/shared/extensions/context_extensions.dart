import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
  double get width => MediaQuery.sizeOf(this).width;
}
