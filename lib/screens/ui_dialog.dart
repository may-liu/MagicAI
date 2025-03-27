import 'package:flutter/material.dart';
import 'package:magicai/modules/controls/input_dialog.dart' as InputDialog;
import 'package:magicai/services/system_manager.dart';

void showNewFileDialog(BuildContext context) {
  InputDialog.showInputPrompt(
    context: context,
    title: '新对话名称',
    placeholder: '新名称',
  ).then(
    (value) =>
        (value != null)
            ? SystemManager.instance.doNewTopic(topic: value)
            : null,
  );
}

void showNewFolderDialog(BuildContext context) {
  InputDialog.showInputPrompt(
    context: context,
    title: '新建组',
    placeholder: '输入组名称',
  ).then(
    (value) =>
        (value != null)
            ? SystemManager.instance.doNewFolder(folder: value)
            : null,
  );
}
