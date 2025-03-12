import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class EnvironmentUtils {
  // static bool get isDesktop => size.width > 600;
  static bool? _isDesktop;

  static bool get isDesktop {
    if (_isDesktop == null) {
      final data = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.single,
      );
      _isDesktop = data.size.width > 600;
    }
    return _isDesktop!;
  }

  static Future<String> configPath() async {
    // Directory d = await getLibraryDirectory();
    // Directory d = await getApplicationDocumentsDirectory();
    Directory d = await getApplicationSupportDirectory();
    return d.path; // Add a return statement here
  }

  static bool get isPC =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);
}
