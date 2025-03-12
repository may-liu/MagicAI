
import 'package:flutter/material.dart';

enum MessageType { User, AI, Thinking, UnInitialized, End }

// 消息数据模型
class ChatMessage {
  String content = '';
  String? senderId = '';
  late int startPos = 0;
  MessageType messageType;

  bool get isUser {
    return messageType == MessageType.User ? true : false;
  }

  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.messageType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

typedef RequestCallback = void Function(MessageType type, String message);
typedef RequestSendingCallback = void Function();
typedef RequestSentCallback = void Function();
typedef ListItemChangedCallback = void Function(VoidCallback callback);
typedef ResponseReceivingCallback = void Function(ChatMessage message);
typedef ResponseDoneCallback = void Function();
typedef MessageTypeChanged = void Function(MessageType from, MessageType to);

abstract class TopicNotifyCallback {
  void onRequestCallback(MessageType type, String message);
  void onRequestSendingCallback();
  void onRequestSentCallback();
  void onListItemChangedCallback(VoidCallback callback);
  void onResponseReceivingCallback(ChatMessage message);
  void onResponseDoneCallback();
  void onMessageTypeChanged(MessageType from, MessageType to);
}

abstract class GptClient {
  Future<List<dynamic>> loadModelList(String url, String apiKey);

  Future<void> sendRequest(
    List<ChatMessage> last,
    String text,
    RequestCallback callback,
    MessageTypeChanged onChanged,
  );

  String get modelId;
  String get systemPrompt;

  void abort();
}
