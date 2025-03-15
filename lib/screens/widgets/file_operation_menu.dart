import 'dart:io';

import 'package:flutter/material.dart';
import 'package:magicai/entity/file_node.dart';
import 'package:magicai/services/system_manager.dart';
import 'package:path/path.dart' as pathLib;

@immutable
class _ContextMenuItem {
  final String label;
  final IconData icon;

  const _ContextMenuItem(this.label, this.icon);
}

// 显示空白菜单
void showEmptySpaceMenu(BuildContext context, Offset position, FileNode node) {
  final emptySpaceMenuItems = const [
    _ContextMenuItem('创建文件', Icons.insert_drive_file),
    _ContextMenuItem('创建文件夹', Icons.create_new_folder),
  ];
  showMenu<_ContextMenuItem>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & MediaQuery.of(context).size,
    ),
    items:
        emptySpaceMenuItems
            .map(
              (item) => PopupMenuItem<_ContextMenuItem>(
                value: item,
                child: ListTile(
                  leading: Icon(item.icon, size: 20),
                  title: Text(item.label),
                  contentPadding: EdgeInsets.zero,
                  minLeadingWidth: 24,
                ),
              ),
            )
            .toList(),
  ).then((selectedItem) {
    if (selectedItem != null) {
      switch (selectedItem.label) {
        case '新建话题':
          _createNewFile(context, node);
          break;
        case '新建目录':
          _createNewFolder(context, node);
          break;
        case '移动':
          _moveFile(context, node);
          break;
        case '删除':
          _deleteFile(context, node);
          break;
        case '打开':
          // _openFile(context, node);
          break;
      }
      // _handleEmptyMenuSelection(selectedItem);
    }
  });
}

// 处理右键点击
void showContextMenu(
  BuildContext context,

  FileNode node,
  Offset position,
) async {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  final emptySpaceMenuItems = const [
    _ContextMenuItem('创建文件', Icons.insert_drive_file),
    _ContextMenuItem('创建文件夹', Icons.create_new_folder),
  ];

  // 添加菜单项定义
  final folderMenuItems = const [
    _ContextMenuItem('创建文件', Icons.insert_drive_file),
    _ContextMenuItem('创建文件夹', Icons.create_new_folder),
    _ContextMenuItem('移动', Icons.drive_file_move),
    _ContextMenuItem('删除', Icons.delete),
  ];

  final fileMenuItems = const [
    _ContextMenuItem('打开', Icons.open_in_new),
    _ContextMenuItem('移动', Icons.drive_file_move),
    _ContextMenuItem('删除', Icons.delete),
  ];

  final selectedItem = await showMenu<_ContextMenuItem>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    ),
    items: [
      ...(node.isDirectory ? folderMenuItems : fileMenuItems).map(
        (item) => PopupMenuItem<_ContextMenuItem>(
          value: item,
          child: ListTile(
            leading: Icon(item.icon, size: 20),
            title: Text(item.label),
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 24,
          ),
        ),
      ),
    ],
  );

  if (selectedItem != null) {
    _handleMenuSelection(context, selectedItem, node);
  }
}

// 示例方法 - 需要根据实际需求实现
Future<Directory?> _createNewFile(BuildContext context, FileNode parent) async {
  debugPrint('创建文件在: ${parent.path}');
  String? path = pathLib.join(parent.path, await _showInputDialog(context));
  path = '$path.md';
  debugPrint('创建文件夹在: $path');

  SystemManager.instance.changeCurrentFile(path);

  return null;
}

Future<Directory?> _createNewFolder(
  BuildContext context,
  FileNode parent,
) async {
  String? path = pathLib.join(parent.path, await _showInputDialog(context));
  debugPrint('创建文件夹在: $path');
  Directory dic = Directory(path);
  if (!await dic.exists()) {
    dic.create(recursive: true);
    return dic;
  }
  return null;
  // Dictionary(parent.path)
  // 实现文件夹创建逻辑
}

// 显示输入对话框的方法
Future<String?> _showInputDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false, // 点击对话框外部不关闭
    builder: (BuildContext context) {
      TextEditingController controller = TextEditingController();
      return AlertDialog(
        title: const Text('请输入内容'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '在这里输入'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
          ),
        ],
      );
    },
  );
}

void _moveFile(BuildContext context, FileNode node) {
  debugPrint('移动文件: ${node.path}');
  // 实现移动逻辑
}

void _deleteFile(BuildContext context, FileNode node) async {
  final confirmed = await showDialog<bool>(
    builder:
        (context) => AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要永久删除 "${node.name}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
    context: context,
  );

  if (confirmed ?? false) {
    // 执行删除操作
  }
  // 实现删除逻辑
}

// 处理菜单选择
Future<Directory?> _handleMenuSelection(
  BuildContext context,
  _ContextMenuItem item,
  FileNode node,
) async {
  switch (item.label) {
    case '创建文件':
      return await _createNewFile(context, node);
    case '创建文件夹':
      return await _createNewFolder(context, node);
    case '移动':
      _moveFile(context, node);
      break;
    case '删除':
      _deleteFile(context, node);
      break;
    case '打开':
      // _openFile(context, node);
      break;
  }
  return null;
}
