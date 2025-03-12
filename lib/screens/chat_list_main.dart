import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:magicai/entity/file_node.dart';
import 'package:magicai/screens/widgets/file_operation_menu.dart';

typedef OnFileSelected = void Function(String filename);

enum RootExpansionMode {
  showCollapsed, // 显示根目录且折叠
  hideAndExpand, // 隐藏根目录直接展开子项
}

class ChatFileList extends StatefulWidget {
  final RootExpansionMode expansionMode;
  final OnFileSelected onFileSelected;
  final Directory topicRoot;

  const ChatFileList({
    super.key,
    this.expansionMode = RootExpansionMode.hideAndExpand,
    required this.onFileSelected,
    required this.topicRoot,
  });

  @override
  State<StatefulWidget> createState() => _ChatFileListState();
}

class _ChatFileListState extends State<ChatFileList> {
  final Map<String, bool> _expansionState = {};
  bool _isInitialized = false;
  late FileNode _root;
  late RootExpansionMode mode;
  @override
  void initState() {
    mode = widget.expansionMode;
    _initializeState();
    super.initState();
  }

  void _initializeState() {
    FileNode.fromDirectory(widget.topicRoot).then((value) {
      _root = value;
      _isInitialized = true;
      if (mode == RootExpansionMode.hideAndExpand) {
        _root.loadChildren().then((_) {
          // 隐藏根节点时自动展开其直接子节点

          setState(() {
            for (var child in _root.children) {
              _expansionState[child.path] = true;
            }
          });
        });
      } else {
        // 显示根节点时初始化折叠状态
        _expansionState[_root.path] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget view =
        _isInitialized
            ? ListView(
              padding: const EdgeInsets.all(16),
              children: _buildRootNodes(),
            )
            : SizedBox.shrink();

    return view;
  }

  void _registerChildren(FileNode parent) {
    for (final child in parent.children) {
      _expansionState.putIfAbsent(child.path, () => false);

      if (child.isDirectory) {
        _registerChildren(child);
      }
    }
  }

  void _handleDoubleTap(FileNode node) async {
    try {
      if (node.isDirectory) {
        final currentState = _expansionState[node.path] ?? false;

        if (!node.isLoaded) {
          final newChildren = await node.loadChildren();
          // 更新为不可变模式
          final newNode = node.copyWith(newChildren);
          _registerChildren(newNode);
          node = newNode;
        }

        setState(() => _expansionState[node.path] = !currentState);
      } else {
        widget.onFileSelected(node.path);
      }
      // ...
    } catch (e) {
      debugPrint('Error handling double tap: $e');
    }
  }

  List<Widget> _buildRootNodes() {
    if (mode == RootExpansionMode.hideAndExpand) {
      // 直接渲染根节点的子节点
      var list = _root.children.map((child) => _buildNode(child, 0)).toList();
      return list;
    }
    // 正常渲染根节点
    return [_buildNode(_root, 0)];
  }

  Widget _buildNode(FileNode node, int depth) {
    final isExpanded = _expansionState[node.path] ?? false;

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS) {
                _handleDoubleTap(node);
              }
            },
            onDoubleTap: () => _handleDoubleTap(node),
            onSecondaryTapDown:
                (details) =>
                    showContextMenu(context, node, details.globalPosition),
            onLongPress: () {
              // 移动端适配：长按触发菜单
              if (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS) {
                final renderBox = context.findRenderObject() as RenderBox;
                showContextMenu(
                  context,
                  node,
                  renderBox.localToGlobal(Offset.zero),
                );
              }
            },
            child: ListTile(
              leading: Icon(
                node.isDirectory ? Icons.folder : Icons.insert_drive_file,
                color:
                    node.isDirectory
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(node.name),
              trailing:
                  node.isDirectory
                      ? Icon(isExpanded ? Icons.expand_less : Icons.expand_more)
                      : null,
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 24,
            ),
          ),
          if (isExpanded && node.isDirectory)
            ...node.children.map((child) => _buildNode(child, depth + 1)),
        ],
      ),
    );
  }
}
