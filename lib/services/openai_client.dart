import 'dart:async';

import 'package:flutter/material.dart';
import 'package:magicai/entity/system_settings.dart';
import 'package:magicai/services/abstract_client.dart';
import 'package:magicai/services/system_manager.dart';

import 'dart:convert';
import 'dart:io';

// ignore: unused_import
import '../entity/pair.dart';

// 工厂类，负责管理 MyClass 实例的创建
class OpenaiClientManager {
  static final OpenaiClientManager _instance = OpenaiClientManager._internal();
  // 静态方法，用于创建 MyClass 实例
  GptClient? getInstance(ModelConfig config) {
    Pair<String, Uri> parseUrl = Pair(config.apiKey, Uri.parse(config.url));

    OpenaiClient? c = _makeInstance(parseUrl);
    c?._config = config;
    return _connectionMappings[parseUrl];
  }

  OpenaiClient? _makeInstance(Pair<String, Uri> parseUrl) {
    if (_connectionMappings.containsKey(parseUrl)) {
      return _connectionMappings[parseUrl];
    } else {
      var c = OpenaiClient._(parseUrl);
      _connectionMappings[parseUrl] = c;
      return c;
    }
  }

  OpenaiClient? fromUrl(String url, String apiKey) {
    Pair<String, Uri> parseUrl = Pair(apiKey, Uri.parse(url));
    return _makeInstance(parseUrl);
  }

  // 字典用于存储键值对
  final Map<Pair<String, Uri>, OpenaiClient> _connectionMappings = {};

  // 公共静态方法，用于获取单例实例
  static OpenaiClientManager get instance => _instance;

  // 私有构造函数，防止外部通过 new 关键字创建实例
  OpenaiClientManager._internal();
}

class OpenaiClient implements GptClient {
  final Pair<String, Uri> _client;
  late ModelConfig _config;

  // 私有静态最终实例，确保在类加载时就初始化
  HttpClientRequest? _request;
  StreamSubscription? _subscription;
  MessageType _current_type = MessageType.User;

  // 私有构造函数，防止外部直接实例化
  OpenaiClient._(this._client, {ModelConfig? config}) {
    if (config == null && SystemManager.instance.currentModel() == null) {
      _config = ModelConfig.byUrl(_client.second.toString(), _client.first);
    } else {
      _config = config ?? SystemManager.instance.currentModel()!;
    }
  }

  static Future<Map<String, dynamic>> _determineScheme(Uri uri) async {
    try {
      HttpClient client = HttpClient();
      final request =
          await client.getUrl(uri)
            ..headers.contentType = ContentType.json
            ..persistentConnection = false;

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );

      final body = await response.transform(utf8.decoder).join();

      return {
        'status': response.statusCode,
        'headers': response.headers,
        'body': body,
        'scheme': uri.scheme,
      };
    } on HandshakeException {
      return {'status': 0, 'headers': {}, 'body': '', 'scheme': 'http'};
    } on TimeoutException catch (e) {
      throw Exception('请求超时: ${e.duration}秒');
    } catch (e) {
      throw Exception('请求失败: ${e.toString()}');
    }
  }

  static Future<String> _determineSchemeByError(
    String host,
    int port,
    String path,
  ) async {
    try {
      var secureClient = HttpClient(context: SecurityContext());
      var request = await secureClient.head(host, port, path);
      await request.close();
      return request.uri.scheme;
    } catch (e) {
      if (e is HandshakeException) {
        try {
          var httpClient = HttpClient();
          var httpRequest = await httpClient.head(host, port, path);
          await httpRequest.close();
          return 'http';
        } catch (httpError) {
          throw 'unknown';
        }
      }
      throw 'unknown';
    }
  }

  //   def get_latest_version():
  //     response = requests.get("https://hunyuan.tencentcloudapi.com/meta/version")
  //     return response.json().get("current_version")

  // version = get_latest_version()
  // print(f"Latest X-TC-Version: {version}")

  static Future<Pair<String, String>> fixChatUrlforInput({
    required String url,
  }) async {
    late Uri uri;
    late String scheme;

    if (!url.startsWith('http') && !url.startsWith('https')) {
      uri = Uri.parse('https://$url');
      scheme = uri.scheme;
      try {
        var map = await _determineScheme(uri);
        scheme = map['scheme'];
      } catch (e) {
        debugPrint('Error: $e');
        return Pair('', '');
      }
    } else {
      uri = Uri.parse(url);
      scheme = uri.scheme;
    }

    List<String> pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) {
      uri = uri.replace(path: 'v1/chat/completions');
      pathSegments = uri.pathSegments;
    }

    if (pathSegments.last != 'completions') {
      uri = uri.replace(path: '${uri.path}/completions');
    }

    return Pair(
      Uri(scheme: scheme, host: uri.host, port: uri.port).toString(),
      Uri(
        scheme: scheme,
        host: uri.host,
        port: uri.port,
        pathSegments: pathSegments,
      ).toString(),
    );
  }

  @override
  Future<List<dynamic>> loadModelList(String url, String apiKey) async {
    Uri uri = Uri.parse(url);
    String scheme = uri.scheme;
    if (scheme == 'http' || scheme == 'https') {
      String host = uri.host;

      List<String> paths = uri.pathSegments;
      late Uri req;
      if (paths.contains('v1')) {
        req = Uri.parse("$scheme://$host:${uri.port}/v1/models");
      } else {
        req = Uri.parse("$scheme://$host:${uri.port}/${paths[0]}/models");
      }

      HttpClient httpClient = HttpClient();

      HttpClientRequest request = await httpClient.getUrl(req);
      request.headers.set('Content-Type', 'application/json; charset=UTF-8');
      request.headers.set('Authorization', 'Bearer $apiKey');
      HttpClientResponse response = await request.close();
      String responseBody = await response.transform(utf8.decoder).join();
      httpClient.close();
      if (response.statusCode == 200) {
        // 请求成功，解析响应数据
        var responseData = json.decode(responseBody);
        return responseData['data'];
      } else {
        // 请求失败，输出错误信息
        debugPrint('Request failed with status: ${response.statusCode}.');
        return [];
      }
    }
    return [];
  }

  @override
  Future<void> sendRequest(
    List<ChatMessage> last,
    String text,
    RequestCallback callback,
    MessageTypeChanged onChanged,
  ) async {
    final prompt =
        SystemManager.instance
            .currentPrompt(); //sysPrompt.replaceAll('\r\n', '\n');

    HttpClient httpClient = HttpClient();
    final fullText = text.replaceAll('\r\n', '\n');

    try {
      httpClient.idleTimeout = Duration(seconds: 30);
      _request = await httpClient.postUrl(_client.second);

      _request!.headers.set('Content-Type', 'application/json; charset=UTF-8');
      _request!.headers.set('Authorization', 'Bearer ${_client.first}');
      // _request!.headers.set('X-TC-Version', '2017-03-12');
      var msgs = [];

      if (prompt.isNotEmpty) {
        msgs.add({"role": "system", "content": prompt});
      }
      if (last.isNotEmpty) {
        for (ChatMessage cm
            in last.length > 20 ? last.sublist(last.length - 20) : last) {
          if (cm.messageType == MessageType.User) {
            msgs.add({"role": "user", "content": cm.content});
          } else if (cm.messageType == MessageType.AI) {
            msgs.add({"role": "assistant", "content": cm.content});
          }
        }
      }
      msgs.add({"role": "user", "content": fullText});

      Map<String, dynamic> jsonBody = {
        'model': SystemManager.instance.currentModel()?.modelId,
        'messages': msgs,
        "temperature": _config.temperature,
        "max_tokens": 16384,
        'stream': true,
      };

      final body = json.encode(jsonBody);

      debugPrint('begin to send: ${_client.second}\n$body');
      if (_current_type != MessageType.User) {
        onChanged(_current_type, MessageType.User);
        _current_type = MessageType.User;
      }
      await callback(MessageType.User, "User", fullText);
      _request!.write(body);

      final response = await _request!.close();

      _subscription = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) async {
            debugPrint('received: $line');
            if (line.isNotEmpty && line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data != '[DONE]') {
                try {
                  final jsonData = json.decode(data);
                  final senderName = jsonData['model'];
                  if (jsonData['choices'] != null &&
                      jsonData['choices'].isNotEmpty &&
                      jsonData['choices'][0]['delta'] != null) {
                    if (jsonData['choices'][0]['delta']['reasoning_content'] !=
                        null) {
                      if (_current_type != MessageType.Thinking) {
                        onChanged(_current_type, MessageType.Thinking);
                        _current_type = MessageType.Thinking;
                      }
                      await callback(
                        MessageType.Thinking,
                        senderName,
                        jsonData['choices'][0]['delta']['reasoning_content'],
                      );
                    }
                    if (jsonData['choices'][0]['delta']['content'] != null) {
                      if (_current_type != MessageType.AI) {
                        onChanged(_current_type, MessageType.AI);
                        _current_type = MessageType.AI;
                      }
                      await callback(
                        MessageType.AI,
                        senderName,
                        jsonData['choices'][0]['delta']['content'],
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Error decoding JSON: $e');
                }
              } else {
                await callback(MessageType.End, "User", '');
                // _subscription?.cancel();
                // _request?.abort();
              }
            } else {
              await callback(MessageType.Error, "SYSTEM", line);
            }
          });
      httpClient.close();
    } catch (e) {
      if (e is SocketException) {
        await callback(MessageType.SocketError, "SYSTEM", e.message);
        // 处理网络连接异常
      } else if (e is HttpException) {
        await callback(MessageType.HttpError, "SYSTEM", e.message);
        // 处理 HTTP 请求异常
      } else {
        await callback(MessageType.Error, "SYSTEM", e.toString());
        // 处理其他未知异常
      }
    } finally {}
  }

  @override
  void abort() {
    _subscription?.cancel();
    _request?.abort();
  }

  @override
  String get modelId => SystemManager.instance.currentModel()?.modelId ?? '';

  @override
  String get systemPrompt => SystemManager.instance.currentPrompt();
}
