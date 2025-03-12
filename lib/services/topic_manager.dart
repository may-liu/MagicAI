// 实体类

import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:magicai/entity/pair.dart';
import 'package:magicai/services/abstract_client.dart';
import 'package:magicai/services/chat_storage.dart';
import 'package:synchronized/synchronized.dart';
import 'package:event_bus/event_bus.dart';

class Topic {
  final String filePath;
  final String title;
  final Lock _lock = Lock();
  final List<ChatMessage> messages = [];
  final Set<TopicNotifyCallback> _eventNotifiers = {};
  final Lock _eventLock = Lock();
  late ChatMessage current = ChatMessage(
    content: '',
    messageType: MessageType.UnInitialized,
  );

  Topic(this.title, this.filePath);

  void regEventNotifier(TopicNotifyCallback callback) {
    _eventNotifiers.add(callback);
  }

  void unRegEventNotifier(TopicNotifyCallback callback) {
    _eventNotifiers.remove(callback);
  }

  Future<void> deleteMessage(int index) async {
    _lock
        .synchronized(() async {
          debugPrint(
            'debug for Delete message: on Delete Message: messages length:${messages.length} & index is $index',
          );
          ChatMessage msg = messages[index];
          await TopicContext.deleteContext(
            msg.startPos,
            messages.sublist(index),
          );
          // messages.removeAt(index);
        })
        .then((value) {
          _eventLock.synchronized(() async {
            for (var element in _eventNotifiers) {
              element.onListItemChangedCallback(() => messages.removeAt(index));
            }
          });
        });
  }

  Future<void> sendMessage(GptClient client, String text) async {
    client.sendRequest(
      messages,
      text,
      (type, message) async {
        if (type == MessageType.End) {
          Pair<int, int> pos = await TopicContext.appendContext(
            current.messageType,
            current.content,
          );
          current.startPos = pos.first;
          _eventLock.synchronized(() async {
            for (var element in _eventNotifiers) {
              element.onResponseDoneCallback();
            }
          });
        }
        if (message.isNotEmpty) {
          if (current.messageType == MessageType.UnInitialized) {
            _eventLock.synchronized(() async {
              for (var element in _eventNotifiers) {
                element.onRequestSentCallback();
              }
            });
            current.content = message;
            current.messageType = type;
            messages.add(current);
            if (type == MessageType.User) {
              Pair<int, int> pos = await TopicContext.appendContext(
                current.messageType,
                current.content,
              );
              current.startPos = pos.first;
            }
          } else {
            current.content += message;
            _eventLock.synchronized(() async {
              for (var element in _eventNotifiers) {
                element.onResponseReceivingCallback(current);
              }
            });
          }
        }
      },
      (from, to) {
        current = ChatMessage(
          content: '',
          messageType: MessageType.UnInitialized,
        );
      },
    );
  }

  Future<bool> loadMessage() async {
    late List<Pair<int, String>> value;
    File file = File(filePath);
    bool exists = file.existsSync();
    if (exists) {
      await _lock.synchronized(() async {
        value = await TopicContext.loadMessages();
      });
      if (value.isNotEmpty) {
        // _messages.clear();
        for (Pair<int, String> element in value.reversed) {
          MessageType type = MessageType.UnInitialized;

          int len = TopicContext.titleSpliter.length;
          bool firstBreak = false;
          int currentPos = 0;

          String txt = element.second;

          for (int i = len; i < txt.length; i++) {
            String p = txt[i];
            if (!firstBreak && p == '\n') {
              firstBreak = true;
              continue;
            }
            if (firstBreak && p == '\n') {
              currentPos = i;
              break;
            }
          }

          late String prefix;
          try {
            prefix = txt.substring(0, currentPos - 1);
          } catch (e) {
            debugPrint('OK');
          }

          if (prefix == TopicContext.titleUser) {
            type = MessageType.User;
          }
          if (prefix == TopicContext.titleThinking) {
            type = MessageType.Thinking;
          }
          if (prefix == TopicContext.titleAI) {
            type = MessageType.AI;
          }

          ChatMessage msg = ChatMessage(
            content: txt.substring(currentPos + 1),
            messageType: type,
          );
          msg.startPos = element.first;
          messages.add(msg);
          _eventLock.synchronized(() async {
            for (var element in _eventNotifiers) {
              element.onResponseReceivingCallback(msg);
            }
          });
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() {
    return '   ';
  }
}

// 单例管理类
class TopicManager {
  // 单例实例
  static final TopicManager _instance = TopicManager._internal();

  String currentKey = '';

  Topic get currentTopic => _keyEntityMap[currentKey]!;
  final EventBus _eventBus = EventBus();

  // 私有构造函数
  TopicManager._internal();

  // 工厂方法返回单例实例
  factory TopicManager() {
    return _instance;
  }

  // 存储 key 和实体类的对应关系
  final Map<String, Topic> _keyEntityMap = {};

  // 添加 key 和实体类的对应关系
  void addTopic(String key, Topic entity) {
    currentKey = key;
    _keyEntityMap[key] = entity;
  }

  bool containsTopic(String key) => _keyEntityMap.containsKey(key);

  // 根据 key 获取实体类
  Topic? getTopic(String key) {
    currentKey = key;
    return _keyEntityMap[key];
  }

  // 移除 key 和实体类的对应关系
  void removeTpoic(String key) {
    _keyEntityMap.remove(key);
  }

  // 获取所有实体类
  List<Topic> getAllKeyEntities() {
    return _keyEntityMap.values.toList();
  }
}
