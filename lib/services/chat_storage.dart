// 文件：chat_storage_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:magicai/entity/pair.dart';
import 'package:magicai/services/abstract_client.dart';
import 'package:magicai/services/topic_manager.dart';
import 'package:magicai/services/system_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  // String name = 'base.md';
  // var _baseDir = await FileStorageUtils.getFilePath(name);

  String filename =
      'C:\\Users\\Liuma\\OneDrive\\Code\\MagicAI\\topics\\历史故事\\测试2.md';
  // 'C:\\Users\\Liuma\\OneDrive\\Code\\MagicAI\\topics\\20250303105229503161596.md';
  await checkFile(filename);
  await readFileBackwards(filename, TopicContext.titleSpliter);

  print('OK');

  // await appendToFile("📌✅👉 User", _baseDir);
}

enum TopicTitle { titleUser, titleThinking, titleAI }

class TopicContext {
  static String titleSpliter = "📌✅👉 ";
  static String titleUser = "📌✅👉 ❤️";
  static String titleThinking = "📌✅👉 Thinking";
  static String titleAI = "📌✅👉 🤖";
  static String titleTimeSpliter = " ⏰ ";

  static Future<Pair<int, int>> appendContext(
    String file,
    MessageType type,
    String name,
    String content,
    DateTime opTime,
  ) async {
    late String prefix;
    switch (type) {
      case MessageType.User:
        prefix = '$titleUser $name';
        break;
      case MessageType.Thinking:
        prefix = titleThinking;
        break;
      case MessageType.AI:
        prefix = '$titleAI $name';
        break;
      default:
        assert(true);
    }
    String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(opTime);
    var c = '\n$prefix$titleTimeSpliter$formattedTime\n\n$content\n';
    return await appendToFile(c, file);
  }

  static Future<Pair<int, int>> insertContext(
    String file,
    int startPos,
    ChatMessage message,
    List<ChatMessage> last,
  ) async {
    await truncateFromEnd(file, startPos);

    Pair<int, int> pos = await appendContext(
      file,
      message.messageType,
      message.senderId!,
      message.content,
      message.opTime,
    );
    message.startPos = pos.first;

    for (var element in last.sublist(1)) {
      Pair<int, int> pos = await appendContext(
        file,
        element.messageType,
        element.senderId!,
        element.content,
        element.opTime,
      );

      element.startPos = pos.first;
    }
    return pos;
  }

  static Future<void> deleteContext(
    String file,
    int startPos,
    List<ChatMessage> last,
  ) async {
    await truncateFromEnd(file, startPos);
    for (var element in last.sublist(1)) {
      Pair<int, int> pos = await appendContext(
        file,
        element.messageType,
        element.senderId!,
        element.content,
        element.opTime,
      );

      element.startPos = pos.first;
    }
  }

  static Future<void> regenerate(
    Topic topic,
    GptClient client,
    int index,
  ) async {
    assert(index >= 0);

    final msgLen = topic.messages.length;

    if (topic.messages[index].messageType == MessageType.AI) {
      assert(msgLen > 1);
      // 如果是AI消息，需要重新生成上一条消息
      await topic.reSendMessage(client, index - 1);
    } else if (topic.messages[index].messageType == MessageType.User) {
      // 如果是用户消息，需要重新生成当前消息
      await topic.reSendMessage(client, index);
    }
  }

  static Future<String> branchMessage(Topic topic, int index) async {
    String filename = await createUniqueFilename(topic.filePath);
    int pos =
        index < topic.messages.length - 1
            ? topic.messages[index + 1].startPos
            : await File(topic.filePath).length();
    await copyFileStreamed(File(topic.filePath), File(filename), pos);
    return filename;
  }

  static Future<Pair<int, int>> appendContextWithoutType(String content) async {
    return await appendToFile(content, SystemManager.instance.currentFile);
  }

  static Future<List<Pair<int, String>>> loadMessages() async {
    return await readFileBackwards(
      SystemManager.instance.currentFile,
      TopicContext.titleSpliter,
    );
  }
}

Future<void> checkFile(String filePath) async {
  File file = File(filePath);
  RandomAccessFile randomAccessFile = await file.open(mode: FileMode.read);
  List<Pair<int, int>> pos = [
    Pair<int, int>(1, 62),
    Pair<int, int>(63, 6290),
    Pair<int, int>(6291, 6343),
    Pair<int, int>(6344, 10241),
    Pair<int, int>(10242, 10372),
    Pair<int, int>(10373, 10749),
  ];
  int index = 0;
  for (var element in pos) {
    int chunkSize = element.second - element.first;
    await randomAccessFile.setPosition(element.first);
    List<int> readBytes = await randomAccessFile.read(chunkSize);
    Utf8Decoder decoder = Utf8Decoder(allowMalformed: false);
    var result = decoder.convert(readBytes);
    debugPrint('debug:$index:$result\n');
    index++;
  }
}

Future<List<Pair<int, String>>> readFileBackwards(
  String filePath,
  String searchTerm,
) async {
  try {
    File file = File(filePath);
    int fileLength = await file.length();
    // int chunkSize = fileLength > 1024 * 1024 ? 4096 : 1024;

    // int chunkSize = fileLength > 32 ? 32 : fileLength; // debug用。
    int position = fileLength;
    List<Pair<int, String>> strs = [];
    Utf8Decoder decoder = Utf8Decoder(allowMalformed: false);

    RandomAccessFile randomAccessFile = await file.open(mode: FileMode.read);

    final List<int> searchBytes = utf8.encode(searchTerm);
    List<int> bytes = List.empty(growable: true);

    while (position > 0) {
      int chunkSize = position > 4096 ? 4096 : position;
      int start = position - chunkSize;
      if (start < 0) {
        start = 0;
      }
      await randomAccessFile.setPosition(start);

      List<int> readBytes = await randomAccessFile.read(chunkSize);

      if (bytes.isNotEmpty) {
        bytes.insertAll(0, readBytes.toList());
        // bytes.insertAll(0, readBytes);
      } else {
        bytes.addAll(readBytes);
      }

      // 将搜索词编码为字节数组
      List<int> indexs = findIndexOfBytes(bytes, searchBytes);
      int end = bytes.length;
      for (var element in indexs) {
        List<int> resultBytes = [];

        resultBytes.addAll(bytes.sublist(element, end));

        String result = '';
        try {
          result = decoder.convert(resultBytes); //utf8.decode(resultBytes);
          bytes = bytes.sublist(0, element);
          end = element;
        } catch (e) {
          if (e is FormatException) {
            debugPrint('$e');
          }
        }

        if (result.isNotEmpty) {
          strs.add(Pair(start + element, result));
        }

        end = element;
      }

      position = start;
    }
    await randomAccessFile.close();
    return strs;
  } catch (e) {
    debugPrint('Error reading file: $e');
    return [];
  }
}

Future<void> copyFileStreamed(
  File sourceFile,
  File destinationFile,
  int pos,
) async {
  // 检查pos是否小于等于源文件的长度
  final sourceLength = await sourceFile.length();
  if (pos > sourceLength) {
    throw ArgumentError(
      'pos must be less than or equal to the length of the source file.',
    );
  }

  // 打开源文件以读取
  final inputStream = sourceFile.openRead(0, pos);

  // 打开目标文件以写入
  final outputStream = destinationFile.openWrite();

  try {
    // 将输入流的数据复制到输出流
    await inputStream.pipe(outputStream);
    // 刷新输出流以确保所有数据都被写入
    await outputStream.flush();
  } catch (e) {
    // 处理复制过程中可能出现的错误
    print('Error copying file: $e');
    rethrow;
  } finally {
    // 关闭输入流和输出流
    await outputStream.close();
  }
}

Future<String> createUniqueFilename(String filePath) async {
  // 创建一个 File 对象
  File file = File(filePath);

  // 获取文件所在的目录路径
  String directory = file.parent.path;

  // 获取文件名
  // String filename = file.path.split('/').last;
  String filename = path.basename(file.path);

  // 分离文件名和扩展名
  String nameWithoutExtension = path.basenameWithoutExtension(file.path);
  String extension = path.extension(file.path);
  // filename.contains('.')
  //     ? '.' + filename.split('.').sublist(1).join('.')
  //     : '';

  int counter = 1;
  String newFilename = filename;

  String newFullPath = path.join(directory, newFilename);

  // 检查文件是否存在，如果存在则生成新的文件名
  while (await File(newFullPath).exists()) {
    newFilename = '$nameWithoutExtension ($counter)$extension';
    counter++;
    newFullPath = path.join(directory, newFilename);
  }

  // 返回新的不重复的文件路径
  return newFullPath;
}

List<int> findIndexOfBytes(List<int> source, List<int> target) {
  List<int> poss = [];
  int pos = source.length;
  while (pos >= 0) {
    pos = findLastIndexOfBytes(source.sublist(0, pos), target);
    if (pos >= 0) {
      poss.add(pos);
    }
  }
  return poss;
}

Future<void> truncateFromEnd(String filePath, int bytesToRemove) async {
  final file = File(filePath);
  final length = await file.length();
  final startPos = bytesToRemove;
  debugPrint(
    'debug for Delete message: on truncateFromEnd: file: $filePath start pos is $startPos, length is $length',
  );
  // 检查文件是否存在
  if (!await file.exists()) throw Exception('文件不存在');

  // 以读写模式打开文件
  final raf = await file.open(mode: FileMode.writeOnlyAppend);
  try {
    final originalLength = await raf.length();

    // 计算新长度（必须非负）
    final newLength = originalLength - bytesToRemove;
    if (newLength < 0) throw ArgumentError('要删除的字节数超过文件长度');

    // 执行截断操作
    await raf.truncate(bytesToRemove);
  } finally {
    await raf.close(); // 必须关闭文件句柄
  }
}

Future<void> updateFileFromPosition(
  String filePath,
  int position,
  String newContent,
) async {
  try {
    File file = File(filePath);
    int length = await file.length();
    RandomAccessFile raf = await file.open(mode: FileMode.write);

    // 将文件指针移动到指定位置
    // await raf.setPosition(position);

    // 从指定位置开始截断文件
    await raf.truncate(length - position);

    if (newContent.isNotEmpty) {
      // 使用 utf8 编码将字符串转换为字节数据
      List<int> data = utf8.encode(newContent);

      // 将新内容写入文件
      await raf.writeFrom(data);
    }

    // 关闭文件
    await raf.close();
  } catch (e) {
    print('Error updating file: $e');
  }
}

// 自定义方法，在字节数组中查找另一个字节数组的最后出现位置
int findLastIndexOfBytes(List<int> source, List<int> target) {
  for (int i = source.length - target.length; i >= 0; i--) {
    bool found = true;
    for (int j = 0; j < target.length; j++) {
      if (source[i + j] != target[j]) {
        found = false;
        break;
      }
    }
    if (found) {
      return i;
    }
  }
  return -1;
}

Future<void> readFileByBlock(String filePath, String delimiter) async {
  try {
    // 创建文件对象
    File file = File(filePath);
    // 以流的方式读取文件内容，返回一个字节流
    Stream<List<int>> byteStream = file.openRead();
    // 将字节流转换为字符串流，使用 UTF-8 解码
    Stream<String> stringStream = byteStream.transform(utf8.decoder);

    String buffer = '';
    // 监听字符串流中的每个数据块
    await for (String chunk in stringStream) {
      buffer += chunk;
      // 按特殊字段分割缓冲区中的内容
      List<String> parts = buffer.split(delimiter);
      // 除了最后一个部分，其他部分都是完整的块
      for (int i = 0; i < parts.length - 1; i++) {
        String block = parts[i];
        // 处理每个块，这里只是简单打印
        print('Block: $block');
      }
      // 将最后一个部分保留在缓冲区中，可能是不完整的块
      buffer = parts.last;
    }

    // 处理最后一个可能剩余的块
    if (buffer.isNotEmpty) {
      print('Block: $buffer');
    }
  } catch (e) {
    debugPrint('Error reading file: $e');
  }
}

Future<Pair<int, int>> appendToFile(String content, String fullpath) async {
  try {
    File file = File(fullpath);

    // 检查文件是否存在，如果不存在则创建
    if (!await file.exists()) {
      await file.create();
    }

    int start = await file.length();

    // 以追加模式打开文件并写入内容
    IOSink sink = file.openWrite(mode: FileMode.append, encoding: utf8);
    sink.write(content);
    await sink.flush();
    await sink.close();
    int end = await file.length();

    print('Content appended to file successfully.');
    return Pair<int, int>(start, end);
  } catch (e) {
    print('Error appending to file: $e');
    return Pair<int, int>(-1, -1);
  }
}

Future<void> addLinesToFileHeadStream(
  String filePath,
  List<String> newLines,
) async {
  try {
    // 创建临时文件
    File tempFile = File('${filePath}_temp');
    IOSink tempSink = tempFile.openWrite();

    // 写入新行
    for (String line in newLines) {
      tempSink.write(line);
    }

    // 逐行读取原文件并写入临时文件
    File file = File(filePath);
    Stream<String> lines = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (String line in lines) {
      tempSink.write(line);
    }

    // 关闭临时文件写入流
    await tempSink.close();

    // 替换原文件
    await tempFile.rename(filePath);

    print('Lines added to the file head successfully.');
  } catch (e) {
    print('Error adding lines to the file head: $e');
  }
}

Future<void> updateFileRange(
  String filePath,
  int start,
  int end,
  String newContent,
) async {
  try {
    // 以读写模式打开文件
    RandomAccessFile file = await File(filePath).open(mode: FileMode.append);

    // 获取原文件长度
    int originalLength = await file.length();

    // 计算更新内容的字节数
    List<int> newContentBytes = newContent.codeUnits;
    int newContentLength = newContentBytes.length;

    // 计算原范围的长度
    int originalRangeLength = end - start;

    // 计算需要调整的文件大小
    int sizeAdjustment = newContentLength - originalRangeLength;

    // 如果需要增加文件大小
    if (sizeAdjustment > 0) {
      // 先将文件指针移动到文件末尾
      await file.setPosition(originalLength);
      // 扩展文件大小以容纳新增内容
      await file.writeByte(0);
      await file.setPosition(originalLength + sizeAdjustment);
      await file.truncate(originalLength + sizeAdjustment);
    } else if (sizeAdjustment < 0) {
      // 如果需要减小文件大小
      // 先将后面的内容向前移动
      List<int> remainingBytes = await file.read(originalLength - end);
      await file.setPosition(start + newContentLength);
      await file.writeFrom(remainingBytes);
      // 截断文件
      await file.setPosition(originalLength + sizeAdjustment);
      await file.truncate(originalLength + sizeAdjustment);
    }

    // 将文件指针移动到起始位置
    await file.setPosition(start);

    // 写入新内容
    await file.writeFrom(newContentBytes);

    // 关闭文件
    await file.close();

    print('File updated successfully.');
  } catch (e) {
    print('Error updating file: $e');
  }
}

// 写入文件
Future<void> writeFile(String content, String fullpath) async {
  // if (kIsWeb) {
  //   saveFileWeb(content, fileName);
  // } else {
  await writeFileByPath(content, fullpath);
  // }
}

Future<String> readFileByPath(String fullPath) async {
  // if (kIsWeb) {
  //   return readFileWeb();
  // } else {
  final file = File(fullPath);
  if (await file.exists()) {
    try {
      String content = await file.readAsString();
      return content;
    } catch (e) {
      debugPrint('文件读取失败: $e');
    }
  }
  return '';
  // }
}

Future<void> writeFileByPath(String content, String fullPath) async {
  final file = File(fullPath);
  try {
    await file.writeAsString(content, flush: true);
  } catch (e) {
    debugPrint('文件写入失败: $e');
  }
}

// 读取文件
Future<String> readFile(String fullPath) async {
  final content = await readFileByPath(fullPath);
  return content;
}

class ChatStorage {
  static final ChatStorage _instance = ChatStorage._internal();
  late Directory _baseDir;

  factory ChatStorage() => _instance;

  ChatStorage._internal() {
    _initStorage();
  }

  Future<void> _initStorage() async {
    _baseDir = Directory(await _getStoragePath());
    if (!await _baseDir.exists()) {
      await _baseDir.create(recursive: true);
    }
  }

  Future<String> _getStoragePath() async {
    if (kIsWeb) {
      // Web环境使用虚拟路径
      return '/chat_history';
    }
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/chat_history';
  }

  String _sanitizeTopic(String topic) {
    // 过滤非法字符并限制长度
    return topic
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(' ', '_')
        .substring(0, 50);
  }

  Future<File> _getTopicFile(String topic) async {
    final sanitizedTopic = _sanitizeTopic(topic);
    final topicDir = Directory('${_baseDir.path}/$sanitizedTopic');
    if (!await topicDir.exists()) {
      await topicDir.create(recursive: true);
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    return File('${topicDir.path}/$timestamp.md');
  }

  Future<void> saveMessage({
    required String topic,
    required String role,
    required String content,
    required BuildContext context,
  }) async {
    final theme = Theme.of(context);
    final file = await _getTopicFile(topic);
    final metadata = {
      'timestamp': DateTime.now().toIso8601String(),
      'theme': {
        // 保存当前主题信息
        'textColor': theme.textTheme.bodyLarge?.color?.value.toRadixString(16),
        'fontFamily': theme.textTheme.bodyLarge?.fontFamily,
      },
      'platform': {
        // 保存平台信息
        'os': Platform.operatingSystem,
        'version': Platform.version,
      },
    };

    final mdContent = '''
---
${const JsonEncoder.withIndent('  ').convert(metadata)}
---

**${role.toUpperCase()}**  
$content
''';

    await file.writeAsString(mdContent);
  }
}
