import 'dart:io';

import 'package:flutter/material.dart';
import 'package:magicai/entity/file_node.dart';
import 'package:magicai/modules/controls/drag_list_view.dart';
import 'package:magicai/services/system_manager.dart';
import 'package:path/path.dart' as PathLib;

typedef OnFileSelected = void Function(String filename);

class MdFileNodeItem extends DragableListItem {
  MdFileNodeItem({
    bool isHovering = false,
    bool isSelected = false,
    required this.index,
    required this.node,
  }) : super(isHovering, isSelected);

  final FileNode node;

  final index;

  @override
  bool get isAcceptable => node.isDirectory;

  @override
  bool moveTo(DragableListItem item) {
    return rename(item.path);
  }

  @override
  String get name => node.name;

  @override
  bool rename(String newName) {
    var newPath = PathLib.join(PathLib.dirname(node.path), newName);
    if (node.isDirectory) {
      Directory(node.path).renameSync(newPath);
      return true;
    } else {
      newPath = PathLib.join(newPath, PathLib.basename(node.path));
      File file = File(node.path);
      try {
        // 重命名文件
        file.renameSync(newPath);
        return true;
      } catch (e) {
        debugPrint('文件重命名失败: $e');
        return false;
      }
    }
  }

  @override
  String get path => node.path;
}

enum RootExpansionMode {
  showCollapsed, // 显示根目录且折叠
  hideAndExpand, // 隐藏根目录直接展开子项
}

class ChatFileListV2 extends StatefulWidget {
  final RootExpansionMode expansionMode;
  final OnFileSelected onFileSelected;
  final Directory topicRoot;
  final bool mobileLayout;

  const ChatFileListV2({
    super.key,
    this.expansionMode = RootExpansionMode.hideAndExpand,
    this.mobileLayout = false,
    required this.onFileSelected,
    required this.topicRoot,
  });

  @override
  State<StatefulWidget> createState() => _ChatFileListState();
}

class _ChatFileListState extends State<ChatFileListV2> {
  final Map<String, bool> _expansionState = {};
  late FileNode _root;
  late String _currentRoot;
  late RootExpansionMode mode;
  late bool _mobileLayout;
  final List<MdFileNodeItem> _items = List.empty(growable: true);
  @override
  void initState() {
    super.initState();
    _mobileLayout = widget.mobileLayout;
    mode = widget.expansionMode;
    _currentRoot = widget.topicRoot.path;
    _initializeRoot(_currentRoot);
    SystemManager.instance.registerLocationEvent((old, now, forcerefrash) {
      if (_currentRoot != now || forcerefrash) {
        _currentRoot = now;
        _initializeRoot(_currentRoot);
      }
    });
  }

  void _initializeRoot(String root) {
    FileNode.fromDirectory(Directory(root)).then((value) {
      _root = value;

      if (mode == RootExpansionMode.hideAndExpand) {
        _root.loadChildren().then((_) {
          // 隐藏根节点时自动展开其直接子节点
          List<FileNode> childrenNode = List.from(_root.children);
          if (SystemManager.instance.needBackToParent()) {
            childrenNode.insert(0, FileNode.subDirectoryNode());
          }

          setState(() {
            _items.clear();
            for (var child in childrenNode) {
              _expansionState[child.path] = true;
              _items.add(MdFileNodeItem(index: _items.length, node: child));
            }
          });
        });
      } else {
        // 显示根节点时初始化折叠状态
        _expansionState[_root.path] = false;
      }
    });
  }

  void reloadItems() {
    _items.clear();
    _initializeRoot(_currentRoot);
  }

  @override
  Widget build(BuildContext context) {
    // Widget view =
    //     _isInitialized
    //         ? ListView(
    //           padding: const EdgeInsets.all(16),
    //           children: _buildRootNodes(),
    //         )
    //         : SizedBox.shrink();

    Widget view = MultiFileDragAndDropPage(
      items: _items,
      mobileLayout: _mobileLayout,
      reloadItemCallback: () => reloadItems(),
      doubleTapItemCallback: (item) {
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('${item.name} 被双击')));

        if (SystemManager.instance.currentModel() == null) {
          // 如果没有配置模型，需要先配置好模型再说
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('请先在配置中配置模型。'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: '确定',
                textColor: Colors.white,
                onPressed: () {
                  // 这里可以添加按钮点击后的处理逻辑
                },
              ),
            ),
          );
        } else {
          if (item is MdFileNodeItem) {
            if (item.node.isSubDirectory) {
              SystemManager.instance.doBackToParent();
            }
            if (item.node.isDirectory) {
              // final currentState = _expansionState[node.path] ?? false;
              SystemManager.instance.doChangeFolder(item.node.path);
            } else {
              widget.onFileSelected(item.node.path);
            }
          }
        }
      },
    );
    return view;
  }
}
