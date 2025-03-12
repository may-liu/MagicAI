// lib/topic_manager.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:event_bus/event_bus.dart';

import 'package:flutter/widgets.dart';
import 'package:magicai/entity/system_settings.dart';
import 'package:magicai/services/chat_storage.dart';
import 'package:magicai/services/file_storage_utils.dart';
import 'package:magicai/services/topic_manager.dart';
// ignore: unused_import
import 'package:path/path.dart' as path;

import 'package:synchronized/synchronized.dart';

typedef LocalFileChangedCallback = Topic Function(LocalFileChangedEvent event);

class LocalFileChangedEvent {
  final String oldTitle;
  final String newTitle;
  final Topic? oldTopic;
  final Topic? newTopic;
  LocalFileChangedEvent(
    this.oldTitle,
    this.newTitle,
    this.oldTopic,
    this.newTopic,
  );
}

class SystemManager {
  late String _configFileName = 'magicAIConfig.json';

  late String _currentChatingFile = '';
  final Lock _configLock = Lock();

  final EventBus _eventBus = EventBus();

  static Future<void> initialize() async {
    _instance = SystemManager._internal();
    await _instance.getSystemConfig();
  }

  void unRegisterEvent(StreamSubscription subscription) {
    subscription.cancel();
  }

  StreamSubscription registerEvent(LocalFileChangedCallback callback) {
    var subscription = _eventBus.on<LocalFileChangedEvent>().listen((event) {
      if (!TopicManager().containsTopic(currentTitle)) {
        Topic t = callback(event);
        TopicManager().addTopic(currentTitle, t);
      } else {
        callback(event);
      }
    });
    return subscription;

    // eventBus.fire(UserLoginEvent('user123'));
  }

  static late final SystemManager _instance;

  SystemManager._internal();

  static SystemManager get instance => _instance;

  String _dataLocation = '';

  Directory _topicLocation = Directory.current;

  String? currentUser() {
    return SystemConfig.instance.userName;
  }

  ModelConfig? currentModel() {
    return SystemConfig.instance.modelConfig.isNotEmpty
        ? SystemConfig.instance.modelConfig[SystemConfig.instance.modelIndex]
        : null;
  }

  String currentPrompt() {
    return SystemConfig.instance.prompts.isNotEmpty
        ? SystemConfig
            .instance
            .prompts[SystemConfig.instance.promptIndex]
            .second
        : '';
  }

  int currentModelIndex() {
    final index = SystemConfig.instance.modelIndex;
    return index < 0 ? -1 : index;
  }

  int currentPromptIndex() {
    final index = SystemConfig.instance.promptIndex;
    return index < 0 ? -1 : index;
  }

  Future<void> doSelectPrompt(int index) async {
    SystemConfig.instance.promptIndex = index;
    await _instance.saveSystemConfig();
  }

  Future<void> doSelectModel(int index) async {
    SystemConfig.instance.modelIndex = index;
    await _instance.saveSystemConfig();
  }

  Future<void> saveSystemConfig() async {
    await _configLock.synchronized(() async {
      var mapping = SystemConfig.instance.toJsonBody();
      Map<String, dynamic> topicFile = {};
      if (_currentChatingFile.isNotEmpty) {
        topicFile = {SystemConfig.instance.userName: _currentChatingFile};
      }
      if (topicFile.isNotEmpty) {
        mapping.addAll({'topic_file': topicFile});
      }
      String jsonStr = jsonEncode(mapping);
      debugPrint('SystemConfig debug: $jsonStr');

      if (_dataLocation.isNotEmpty) {
        await FileStorageUtils.writeFileByPath(jsonStr, _configFileName);
      } else {
        await FileStorageUtils.writeFile(jsonStr, _configFileName);
      }
    });
  }

  Future<SystemConfig> getSystemConfig() async {
    late SystemConfig result; // 提前定义
    await _configLock.synchronized(() async {
      final location = await FileStorageUtils.readFile('data.json');
      late String jsonStr = '';
      if (location.isNotEmpty) {
        var filepath = jsonDecode(location)['data_path'];
        _dataLocation = filepath;
        _topicLocation = Directory(path.join(_dataLocation, "topics"));
        _configFileName = path.join(filepath, _configFileName);
        debugPrint('config file path moved to $_configFileName');
        jsonStr = await FileStorageUtils.readFileByPath(_configFileName);
      } else {
        var base = await FileStorageUtils.getDefaultPath();

        _topicLocation = Directory(path.join(base.path, "topics"));
        jsonStr = await FileStorageUtils.readFile(_configFileName);
      }

      if (!await _topicLocation.exists()) {
        await _topicLocation.create(recursive: true);
      }

      if (jsonStr.isNotEmpty) {
        var jsonObj = jsonDecode(jsonStr);
        SystemConfig.instance.fromJsonBody(jsonObj);
        if (jsonObj.containsKey("topic_file")) {
          _currentChatingFile =
              jsonObj["topic_file"][SystemConfig.instance.userName];
        }
      }

      result = SystemConfig.instance;
    });
    return result;
  }

  Future<void> setDataLocation(String? value) async {
    if (value != null && value.isNotEmpty) {
      await FileStorageUtils.writeFile(
        jsonEncode({'data_path': value}),
        'data.json',
      );
      _dataLocation = value;
      _configFileName = path.join(_dataLocation, _configFileName);

      _topicLocation = Directory(path.join(_dataLocation, "topics"));

      if (!await _topicLocation.exists()) {
        _topicLocation.create(recursive: true);
      }
    }
  }

  String generateFileNameWithTimestampAndRandom(String extension) {
    // 获取当前时间戳
    String timestamp = DateFormat('yyyyMMddHHmmssSSS').format(DateTime.now());
    // 生成随机数
    Random random = Random();
    int randomNumber = random.nextInt(1000000); // 生成 0 到 999999 之间的随机数
    // 结合时间戳、随机数和扩展名生成文件名
    return '$timestamp$randomNumber.$extension';
  }

  String get dataLocation => _dataLocation;

  Directory get topicRoot => _topicLocation;

  String get currentFile {
    if (_currentChatingFile.isEmpty) {
      _currentChatingFile = generateFileNameWithTimestampAndRandom('md');
    }
    return path.join(_topicLocation.path, _currentChatingFile);
  }

  String get currentTitle {
    return path.basenameWithoutExtension(_currentChatingFile);
  }

  String fullPathForTopic(String title) {
    return path.join(_topicLocation.path, '$title.md');
  }

  void changeCurrentFile(String filename, {bool force = false}) {
    String relativePath = path.relative(filename, from: _topicLocation.path);
    if (force ||
        (relativePath.isNotEmpty && relativePath != _currentChatingFile)) {
      String relativePath = path.relative(filename, from: _topicLocation.path);
      Topic? oldTopic = TopicManager().getTopic(currentTitle);
      String oldTitle = currentTitle;

      _currentChatingFile = relativePath;

      Topic t = Topic(currentTitle, filename);
      t.loadMessage().then((value) {
        if (value) {
          TopicManager().addTopic(currentTitle, t);
          _eventBus.fire(
            LocalFileChangedEvent(oldTitle, currentTitle, oldTopic, t),
          );
          TopicManager().removeTpoic(oldTitle);

          SystemManager.instance.saveSystemConfig();
        }
      });
    }
  }

  void branchMessage(int index) {
    Topic? topic = TopicManager().getTopic(currentTitle);
    assert(topic != null);

    TopicContext.branchMessage(topic!, index).then((value) {
      String relativePath = path.relative(value, from: _topicLocation.path);
      _currentChatingFile = relativePath;
      Topic t = Topic(currentTitle, value);
      t.loadMessage();
      TopicManager().addTopic(currentTitle, t);
      SystemManager.instance.saveSystemConfig();
      _eventBus.fire(
        LocalFileChangedEvent(currentTitle, currentTitle, topic, t),
      );
    });
  }
}
