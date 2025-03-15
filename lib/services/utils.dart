import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class EnvironmentUtils {
  // 检查字符串是否为空

  // static late String apiKey;
  // static bool isInitialized = false;

  // static Future<void> initialize() async {
  //   if (isInitialized) {
  //     return;
  //   }
  //   // 模拟异步网络请求
  //   await Future.delayed(const Duration(seconds: 1));
  //   apiKey = "your_api_key_from_network";
  //   isInitialized = true;
  // }

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
