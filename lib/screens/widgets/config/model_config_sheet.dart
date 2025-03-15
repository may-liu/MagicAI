import 'package:flutter/material.dart';
import 'package:magicai/entity/pair.dart';
import 'package:magicai/entity/system_settings.dart';
import 'package:magicai/modules/controls/adaptive_bottom_sheet.dart';
import 'package:magicai/modules/controls/async_button.dart';
import 'package:magicai/services/openai_client.dart';

class ModelConfigSheet extends AdaptiveBottomSheet {
  final ModelConfig? modelConfig;

  final ValueChanged<ModelConfig> onModelSave;
  ModelConfigSheet({super.key, required this.onModelSave, this.modelConfig})
    : super(
        child: _ModelConfigContent(onModelSave, modelConfig),
        minWidthRatio: 0.6, // 可自定义最小宽度比例
      );
}

// 配置内容组件
class _ModelConfigContent extends StatefulWidget {
  final ValueChanged<ModelConfig> onModelSave;
  final ModelConfig? _modelConfig;
  const _ModelConfigContent(this.onModelSave, this._modelConfig);

  @override
  State<_ModelConfigContent> createState() => _ModelConfigContentState();
}

class SelectedItem {
  final double value;
  final String label;
  bool isSelected;

  SelectedItem(this.value, {this.isSelected = false, this.label = ''});

  @override
  String toString() {
    return 'SelectedItem{value: $value, isSelected: $isSelected}';
  }
}

class _ModelConfigContentState extends State<_ModelConfigContent> {
  final _formKey = GlobalKey<FormState>();
  bool _showApiKey = false;
  late TextEditingController _urlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelIdController;
  late TextEditingController _modelNameController;
  int _modelTempSelectedIndex = 0;
  final List<SelectedItem> _modelTempValues = [
    SelectedItem(0.0, label: "数学/编程问题"),
    SelectedItem(1.0, label: "数据抽取/分析"),
    SelectedItem(1.3, label: "通用对话"),
    SelectedItem(1.3, label: "翻译"),
    SelectedItem(1.5, label: "创意/写作"),
  ];

  int _historyLengthIndex = 0;
  final List<SelectedItem> _historyLengthValues = [
    SelectedItem(5, label: "短"),
    SelectedItem(10, label: "较短"),
    SelectedItem(15, label: "中等"),
    SelectedItem(20, label: "长（推荐）"),
    SelectedItem(100, label: "怒长(需要模型支持)"),
  ];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget._modelConfig?.url);
    _apiKeyController = TextEditingController(
      text: widget._modelConfig?.apiKey,
    );
    _modelIdController = TextEditingController(
      text: widget._modelConfig?.modelId,
    );
    _modelNameController = TextEditingController(
      text: widget._modelConfig?.modelName,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _modelIdController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          _buildHeader(),
          const Divider(height: 1),

          // 表单内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildModelNameField(),
                  const SizedBox(height: 20),
                  _buildBaseConfigSection(),
                  const SizedBox(height: 20),
                  _buildModelConfigSection(),
                ],
              ),
            ),
          ),

          // 操作按钮
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('模型配置', style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildModelNameField() {
    return TextFormField(
      controller: _modelNameController,
      decoration: InputDecoration(
        labelText: '模型名称',
        prefixIcon: const Icon(Icons.model_training),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      validator: (value) => value?.isEmpty ?? true ? '请输入模型名称' : null,
    );
  }

  Widget _buildBaseConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('基础配置', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'API地址',
            prefixIcon: const Icon(Icons.link),
            border: const OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? '请输入API地址' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _apiKeyController,
          obscureText: !_showApiKey,
          decoration: InputDecoration(
            labelText: 'API密钥',
            prefixIcon: const Icon(Icons.key),
            suffixIcon: IconButton(
              icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showApiKey = !_showApiKey),
            ),
            border: const OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? '请输入API密钥' : null,
        ),
      ],
    );
  }

  void _showSelectionSheet() async {
    Pair<String, String> input = await OpenaiClient.fixChatUrlforInput(
      url: _urlController.text,
    );
    setState(() {
      _urlController.text = input.second;
    });
    var value = await OpenaiClientManager.instance
        .fromUrl(_urlController.text, _apiKeyController.text)
        ?.loadModelList(_urlController.text, _apiKeyController.text);
    if (value != null && value.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder:
            (context) => Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ListView(
                shrinkWrap: true,
                children:
                    value
                        .map(
                          (e) => ListTile(
                            title: Text(e['id']),
                            onTap: () {
                              setState(() {
                                _modelIdController.text = e['id'];
                              });

                              Navigator.pop(context);
                            },
                          ),
                        )
                        .toList(),
              ),
            ),
      );
    }
  }

  Widget _buildModelConfigSection() {
    _modelTempSelectedIndex =
        widget._modelConfig?.temperature == null
            ? 0
            : _modelTempValues.indexWhere(
              (element) => element.value == widget._modelConfig?.temperature,
            );
    _historyLengthIndex =
        widget._modelConfig?.pageSize == null
            ? 0
            : _historyLengthValues.indexWhere(
              (element) => element.value == widget._modelConfig?.pageSize,
            );
    _modelTempSelectedIndex =
        _modelTempSelectedIndex < 0 ? 0 : _modelTempSelectedIndex;
    _historyLengthIndex = _historyLengthIndex < 0 ? 0 : _historyLengthIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('模型配置', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: _modelIdController,
          decoration: InputDecoration(
            labelText: '模型ID',
            prefixIcon: const Icon(Icons.settings),
            suffixIcon: AsyncButton(
              onPressed: () async {
                _showSelectionSheet();
              },
              child: const Text('检查'),
            ),
            border: const OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? '请输入模型ID' : null,
        ),
        const SizedBox(height: 12),
        Text(
          '当前功能选择: ${_modelTempValues[_modelTempSelectedIndex].label}',
          style: const TextStyle(fontSize: 16),
        ),
        Slider(
          value: _modelTempSelectedIndex.toDouble(),
          min: 0,
          max: _modelTempValues.length - 1,
          divisions: _modelTempValues.length - 1,
          label: _modelTempValues[_modelTempSelectedIndex].label,
          onChanged: (value) {
            setState(() => _modelTempSelectedIndex = value.toInt());
            widget._modelConfig?.temperature =
                _modelTempValues[_modelTempSelectedIndex].value;
          },

          thumbColor: Colors.blue,
          activeColor: Colors.blue[200],
          inactiveColor: Colors.grey[300],
        ),
        const SizedBox(height: 12),
        Text(
          '当前历史记忆长度: ${_historyLengthValues[_historyLengthIndex].label}',
          style: const TextStyle(fontSize: 16),
        ),
        Slider(
          value: _historyLengthIndex.toDouble(),
          min: 0,
          max: _historyLengthValues.length - 1,
          divisions: _historyLengthValues.length - 1,
          label: _historyLengthValues[_historyLengthIndex].label,
          onChanged: (value) {
            setState(() => _historyLengthIndex = value.toInt());
            widget._modelConfig?.pageSize =
                _historyLengthValues[_historyLengthIndex].value.toInt();
          },
          // 自定义滑块外观
          thumbColor: Colors.blue,
          activeColor: Colors.blue[200],
          inactiveColor: Colors.grey[300],
        ),
        // RangeSlider(
        //   values: _modelTempValues, // 类型为 RangeValues
        //   min: 0,
        //   max: 100,
        //   divisions: 20,
        //   labels: RangeLabels(
        //     _modelTempValues.start.round().toString(),
        //     _modelTempValues.end.round().toString(),
        //   ),
        //   onChanged: (RangeValues values) {
        //     setState(() {
        //       _modelTempValues = values;
        //     });
        //   },
        // ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Center(
            child: InkWell(
              onTap: _submitForm,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fillUnComplate() {
    String url = _urlController.text;
    if (!url.startsWith('https://')) {
      _urlController.text = 'https://$url';
    }

    if (!url.endsWith('/completions')) {
      _urlController.text = '$url/completions';
    }

    if (_urlController.text.isEmpty) {
      _urlController.text =
          'https://api.openai.com/v1/engines/davinci-codex/completions';
    }
    if (_apiKeyController.text.isEmpty) {
      _apiKeyController.text = 'sk-xxxxxx';
    }
    if (_modelIdController.text.isEmpty) {
      _modelIdController.text = 'davinci-codex';
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // 这里处理表单提交逻辑
      final config = {
        'modelName': _modelNameController.text,
        'apiUrl': _urlController.text,
        'key': _apiKeyController.text,
        'modelId': _modelIdController.text,
      };

      widget.onModelSave(
        ModelConfig(
          _modelNameController.text,
          _urlController.text,
          _apiKeyController.text,
          -1,
          _modelIdController.text,
          _historyLengthValues[_historyLengthIndex].value.toInt(),
          _modelTempValues[_modelTempSelectedIndex].value.toDouble(),
          1,
        ),
      );
      debugPrint('配置已保存: $config');
      Navigator.pop(context);
    }
  }
}
