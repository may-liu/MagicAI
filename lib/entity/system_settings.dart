import 'dart:convert';
import 'dart:io';

import 'package:magicai/entity/pair.dart';
import 'package:path_provider/path_provider.dart';

class ModelConfig {
  int index = 0;
  String modelName = '';
  String url = '';
  String apiKey = '';
  String modelId = '';
  double temperature = 0.0;
  double topP = 1.0;
  int pageSize = 5;

  ModelConfig(
    this.modelName,
    this.url,
    this.apiKey,
    this.index,
    this.modelId,
    this.pageSize,
    this.temperature,
    this.topP,
  );
  ModelConfig.fromJsonBody(this.modelName, Map<String, dynamic> modelBody) {
    index = modelBody['index'];
    url = modelBody['url'];
    apiKey = modelBody['api_key'];
    modelId = modelBody['model_id'];
    pageSize = modelBody['page_size'];
    temperature = modelBody['temp'];
    topP = modelBody['top_p'];
  }

  Map<String, dynamic> toConfigWithoutName() {
    return {
      'index': index,
      'url': url,
      'api_key': apiKey,
      'model_id': modelId,
      'page_size': pageSize,
      'top_p': topP,
      'temp': temperature,
    };
  }

  Map<String, dynamic> toConfig() {
    return {
      "model_name": modelName,
      'index': index,
      'url': url,
      'api_key': apiKey,
      'model_id': modelId,
      'page_size': pageSize,
      'top_p': topP,
      'temp': temperature,
    };
  }
}

class SystemConfig {
  String userName = '默认用户';
  int modelIndex = -1;
  int promptIndex = -1;
  List<ModelConfig> modelConfig = [];
  List<Pair<String, String>> prompts = [];
  static final SystemConfig _instance = SystemConfig._internal();

  SystemConfig._internal();

  static SystemConfig get instance => _instance;

  void fromJsonBody(Map<String, dynamic> jsonBody) {
    if (jsonBody.isNotEmpty) {
      _instance.userName = jsonBody['userName'];

      final subMapping = jsonBody['model_mapping'][userName];

      for (String name in subMapping.keys) {
        _instance.modelConfig.add(
          ModelConfig.fromJsonBody(name, subMapping[name]),
        );
      }
      _instance.modelConfig.sort((a, b) => a.index.compareTo(b.index));
      if (_instance.modelConfig.isNotEmpty) {
        _instance.modelIndex =
            jsonBody.containsKey('model_index') ? jsonBody['model_index'] : 0;
      }

      if (jsonBody.containsKey('prompts_index')) {
        SystemConfig.instance.promptIndex = jsonBody['prompts_index'];
      }

      if (jsonBody.containsKey('prompts')) {
        List<dynamic> list = jsonBody['prompts'][userName];
        for (var item in list) {
          SystemConfig.instance.prompts.add(
            Pair(item['first']!, item['second']!),
          );
        }
      }
    }
  }

  void addModelInst(ModelConfig config) {
    modelConfig.add(config);

    // writeJsonFile(toJsonBody(), 'system.json');
  }

  void addModel(
    String name,
    String url,
    String apiKey,
    String modelId,
    double temp,
    double topP,
    int pageSize,
    int index,
  ) {
    ModelConfig cfg = ModelConfig(
      name,
      url,
      apiKey,
      index,
      modelId,
      pageSize,
      temp,
      topP,
    );
    addModelInst(cfg);
  }

  Map<String, dynamic> toJsonBody() {
    Map<String, dynamic> jsonBody = {};
    jsonBody['userName'] = userName;
    jsonBody['model_index'] = modelIndex;
    jsonBody['model_mapping'] = {};
    // jsonBody['model_mapping'][userName] = {};
    jsonBody['model_mapping'] = {userName: {}}; // 确保外层 Map 存在
    var subMapping = jsonBody['model_mapping'][userName];

    for (ModelConfig model in modelConfig) {
      subMapping[model.modelName] = model.toConfigWithoutName();
    }

    if (prompts.isNotEmpty) {
      jsonBody['prompts'] ??= {}; // 仅当 prompts 不存在时初始化
      jsonBody['prompts'][userName] = [];
      // if (!jsonBody.containsKey('prompts')) {
      //   jsonBody['prompts'] = {};
      //   jsonBody['prompts'][userName] = [];
      // }

      jsonBody['prompts_index'] = promptIndex;
      jsonBody['prompts'][userName] = List.empty(growable: true);

      for (Pair<String, String> item in prompts) {
        jsonBody['prompts'][userName].add({
          'first': item.first,
          'second': item.second,
        });
      }
    }

    return jsonBody;
  }
}

// 写入 JSON 文件
Future<void> writeJsonFile(Map<String, dynamic> data, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  final jsonString = json.encode(data);
  await file.writeAsString(jsonString);
}

// 读取 JSON 文件
Future<Map<String, dynamic>> readJsonFile(String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  if (await file.exists()) {
    final jsonString = await file.readAsString();
    return json.decode(jsonString);
  }
  return {};
}

Future<SystemConfig> getSystemConfig() async {
  Map<String, dynamic> jsonBody = await readJsonFile('system.json');
  SystemConfig.instance.fromJsonBody(jsonBody);
  return SystemConfig.instance;
}
