import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // 引入 kIsWeb 所在的包
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class FileStorageUtils {
  static Future<Directory> getDefaultPath() async {
    late Directory directory;
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform does not support this method of file storage.',
      );
    } else if (Platform.isAndroid) {
      directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      directory = await getApplicationSupportDirectory();
    }
    return directory;
  }

  // 获取文件路径
  static Future<String> getFilePath(String fileName) async {
    late Directory directory;
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform does not support this method of file storage.',
      );
    } else if (Platform.isAndroid) {
      directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      directory = await getApplicationSupportDirectory();
    }
    return '${directory.path}/$fileName';
  }

  static Future<void> writeFileByPath(String content, String fullPath) async {
    final file = File(fullPath);
    try {
      debugPrint(
        'SystemConfig debug: 写入文件:$fullPath - $content, 长度${content.length}',
      );
      await file.writeAsString(
        content,
        flush: true,
        mode: FileMode.writeOnly,
        encoding: utf8,
      );
    } catch (e) {
      debugPrint('文件写入失败: $e');
    }
  }

  // 写入文件
  static Future<void> writeFile(String content, String fileName) async {
    // if (kIsWeb) {
    //   saveFileWeb(content, fileName);
    // } else {
    final filePath = await getFilePath(fileName);
    debugPrint('保存文件:$content \n到文件路径: $filePath');
    await writeFileByPath(content, filePath);
    // }
  }

  static Future<String> readFileByPath(String fullPath) async {
    // if (kIsWeb) {
    //   return readFileWeb();
    // } else {
    final file = File(fullPath);
    if (await file.exists()) {
      try {
        String content = await file.readAsString(encoding: utf8);
        debugPrint(
          'SystemConfig debug: 读取文件:$fullPath - $content, 长度${content.length}',
        );
        return content;
      } catch (e) {
        debugPrint('文件读取失败: $e');
      }
    }
    return '';
    // }
  }

  // 读取文件
  static Future<String> readFile(String fileName) async {
    // if (kIsWeb) {
    //   return readFileWeb();
    // } else {
    final filePath = await getFilePath(fileName);
    final content = await readFileByPath(filePath);
    return content;
    // }
  }

  // // Web 平台保存文件
  // static void saveFileWeb(String content, String fileName) {
  //   if (kIsWeb) {
  //     final bytes = content.codeUnits;
  //     final blob = html.Blob([bytes]);
  //     final url = html.Url.createObjectUrlFromBlob(blob);
  //     final anchor =
  //         html.document.createElement('a') as html.AnchorElement
  //           ..href = url
  //           ..download = fileName;
  //     anchor.click();
  //     html.Url.revokeObjectUrl(url);
  //   }
  // }

  // // Web 平台读取文件
  // static Future<String> readFileWeb() async {
  //   if (kIsWeb) {
  //     final input = html.FileUploadInputElement()..accept = '.txt';
  //     input.click();
  //     await input.onChange.first;
  //     final files = input.files;
  //     if (files != null && files.isNotEmpty) {
  //       final file = files.first;
  //       final reader = html.FileReader();
  //       reader.readAsText(file);
  //       await reader.onLoad.first;
  //       return reader.result as String;
  //     }
  //     return '';
  //   }
  //   return '';
  // }
}

void main() async {
  // if (kIsWeb) {
  //   FileStorageUtils.saveFileWeb('Hello, Web!', 'test.txt');
  //   final content = await FileStorageUtils.readFileWeb();
  //   print(content);
  // } else {
  await FileStorageUtils.writeFile('Hello, World!', 'test.txt');
  final content = await FileStorageUtils.readFile('test.txt');
  print(content);
  // }
}
