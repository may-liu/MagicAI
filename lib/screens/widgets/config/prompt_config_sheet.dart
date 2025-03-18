// 模型配置弹窗继承基础组件
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:magicai/entity/pair.dart';
import 'package:magicai/modules/controls/adaptive_bottom_sheet.dart';

class PromptConfigSheet extends AdaptiveBottomSheet {
  final Pair<String, String>? promptConfig;

  final ValueChanged<Pair<String, String>> onPromptSave;
  PromptConfigSheet({super.key, required this.onPromptSave, this.promptConfig})
    : super(
        child: _PromptConfigContent(onPromptSave, promptConfig),
        minWidthRatio: 0.6, // 可自定义最小宽度比例
      );
}

// 配置内容组件
class _PromptConfigContent extends StatefulWidget {
  final ValueChanged<Pair<String, String>> onModelSave;
  final Pair<String, String>? _promptConfig;

  const _PromptConfigContent(this.onModelSave, this._promptConfig);

  @override
  State<_PromptConfigContent> createState() => _ModelConfigContentState();
}

class _ModelConfigContentState extends State<_PromptConfigContent> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _textFieldKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _promptController = TextEditingController();
  late TextEditingController _promptNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget._promptConfig != null) {
      _promptNameController = TextEditingController(
        text: widget._promptConfig?.first,
      );
      _promptController = TextEditingController(
        text: widget._promptConfig?.second,
      );
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _promptNameController.dispose();
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
                  // _buildModelNameField(),
                  const SizedBox(height: 20),
                  _buildBaseConfigSection(),
                  const SizedBox(height: 20),
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
          Text('提示词配置', style: Theme.of(context).textTheme.titleLarge),
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
      controller: _promptNameController,
      decoration: InputDecoration(
        labelText: '提示词名称',
        prefixIcon: const Icon(Icons.model_training),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      validator: (value) => value?.isEmpty ?? true ? '请输入提示词名称' : null,
    );
  }

  Widget _buildBaseConfigSection() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(), // 禁用过度滚动效果
      keyboardDismissBehavior:
          Platform.isIOS
              ? ScrollViewKeyboardDismissBehavior.onDrag
              : ScrollViewKeyboardDismissBehavior.manual,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('基础配置', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextFormField(
            controller: _promptNameController,
            decoration: InputDecoration(
              labelText: '提示词名称',
              prefixIcon: const Icon(Icons.link),
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? '请输入提示词名称' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: _textFieldKey,
            focusNode: _focusNode,
            controller: _promptController,
            minLines: 5,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            // obscureText: !_showApiKey,
            decoration: InputDecoration(
              labelText: '提示词内容',
              prefixIcon: const Icon(Icons.anchor_sharp),
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? '请输入提示词内容' : null,
            onTap: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Scrollable.ensureVisible(
                  _textFieldKey.currentContext!,
                  alignmentPolicy:
                      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            },
          ),
        ],
      ),
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

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // 这里处理表单提交逻辑

      widget.onModelSave(
        Pair(_promptNameController.text, _promptController.text),
      );
      Navigator.pop(context);
    }
  }
}
