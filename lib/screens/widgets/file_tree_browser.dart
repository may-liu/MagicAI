import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:magicai/entity/file_node.dart';
import 'package:magicai/screens/widgets/file_operation_menu.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const FileTreeApp());

class FileTreeApp extends StatelessWidget {
  const FileTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    getApplicationDocumentsDirectory().then((value) {});
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: FileTreeBrowser(
        rootDirectory: kIsWeb ? Directory.current : Directory("D:\\Documents"),
        onFileSelected: (filename) {},
      ),
    );
  }
}

typedef OnFileSelected = void Function(String filename);

class FileTreeBrowser extends StatefulWidget {
  final Directory rootDirectory; //;
  final OnFileSelected onFileSelected;
  const FileTreeBrowser({
    super.key,
    required this.rootDirectory,
    required this.onFileSelected,
  });

  @override
  State<FileTreeBrowser> createState() => _FileTreeBrowserState();
}

class _FileTreeBrowserState extends State<FileTreeBrowser> {
  late Future<FileNode> _rootFuture;

  @override
  void initState() {
    super.initState();
    _rootFuture = _getRootDirectory();
  }

  Future<FileNode> _getRootDirectory() async {
    // var root = await FileNode.fromDirectory(widget.rootDirectory);
    // return root.loadRootDirectory();
    return FileNode.fromDirectory(widget.rootDirectory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('File Browser')),
      body: FutureBuilder<FileNode>(
        future: _rootFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FileTreeWidget(
              root: snapshot.data!,
              onFileSelected: widget.onFileSelected,
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

enum RootExpansionMode {
  showCollapsed, // 显示根目录且折叠
  hideAndExpand, // 隐藏根目录直接展开子项
}

class FileTreeWidget extends StatefulWidget {
  final FileNode root;
  final RootExpansionMode expansionMode;
  final OnFileSelected onFileSelected;

  const FileTreeWidget({
    super.key,
    required this.root,
    required this.onFileSelected,
    this.expansionMode = RootExpansionMode.hideAndExpand,
  });

  @override
  State<FileTreeWidget> createState() => _FileTreeWidgetState();
}

class _FileTreeWidgetState extends State<FileTreeWidget> {
  // 使用Map来跟踪节点状态
  final Map<String, bool> _expansionState = {};

  @override
  void initState() {
    super.initState();
    // _expansionState[widget.root.path] = false;
    _initializeState();
  }

  void _registerChildren(FileNode parent) {
    for (final child in parent.children) {
      _expansionState.putIfAbsent(child.path, () => false);

      if (child.isDirectory) {
        _registerChildren(child);
      }
    }
  }

  void _initializeState() {
    if (widget.expansionMode == RootExpansionMode.hideAndExpand) {
      widget.root.loadChildren().then((_) {
        // 隐藏根节点时自动展开其直接子节点

        setState(() {
          for (var child in widget.root.children) {
            _expansionState[child.path] = true;
          }
        });
      });
    } else {
      // 显示根节点时初始化折叠状态
      _expansionState[widget.root.path] = false;
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
        Navigator.pop(context);
      }
      // ...
    } catch (e) {
      debugPrint('Error handling double tap: $e');
    }
  }

  void _openFile(BuildContext context, FileNode file) {
    // 这里可以添加具体的文件打开逻辑
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Open File'),
            content: Text('Opening: ${file.name}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  // 处理空白处点击
  void _handleEmptySpaceTap(TapDownDetails details, BuildContext context) {
    if (_isTapOnEmptySpace(details.globalPosition)) {
      showEmptySpaceMenu(context, details.globalPosition, widget.root);
    }
  }

  void _handleEmptySpaceLongPress(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      final renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      if (_isTapOnEmptySpace(position)) {
        showEmptySpaceMenu(context, position, widget.root);
      }
    }
  }

  // 获取当前父节点（根据展开模式）
  FileNode _getCurrentParentNode() {
    if (widget.expansionMode == RootExpansionMode.hideAndExpand) {
      return widget.root;
    }
    return widget.root;
  }

  bool _isPartOfListItem(RenderBox target) {
    RenderObject? current = target;
    while (current != null) {
      // 检查 debugCreator 是否为 RenderObjectElement 类型
      if (current.debugCreator is RenderObjectElement) {
        RenderObjectElement element =
            current.debugCreator as RenderObjectElement;
        if (element.widget.key == const ValueKey('FileTreeItem')) {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }

  // bool _isPartOfListItem(RenderBox target) {
  //   // 向上遍历渲染树查找特征组件
  //   RenderObject? current = target;
  //   while (current != null) {
  //     // 检查是否包含列表项的特征Widget
  //     RenderObject? parentRenderObject = target.parent;
  //     Element? parentElement = parentRenderObject as Element?;
  //     if (parentElement is ListTile) {
  //       return true;
  //     }
  //     // 或者检查特定Key
  //     if (parentElement?.widget == const ValueKey('FileTreeItem')) {
  //       return true;
  //     }

  //     current = current.parent;
  //   }
  //   return false;
  // }

  // 判断是否点击在空白处
  bool _isTapOnEmptySpace(Offset globalPosition) {
    final RenderBox listViewBox = context.findRenderObject() as RenderBox;
    final localPosition = listViewBox.globalToLocal(globalPosition);

    // 检查是否在列表内容区域外
    if (!listViewBox.size.contains(localPosition)) return false;

    // 查找点击位置的节点
    final hit = BoxHitTestResult();
    WidgetsBinding.instance.hitTest(hit, globalPosition);

    // 检查是否命中任何列表项
    bool hitListItem = hit.path.any((entry) {
      final target = entry.target;
      if (target is! RenderBox) return false;

      // 通过组件树特征判断
      return _isPartOfListItem(target);
    });

    return !hitListItem;

    // hit.path.forEach((entry) {
    //   final target = entry.target;
    //   if (target is RenderBox) {

    //     final box = entry.target;
    //     if ()
    //     final box = entry.target as RenderBox;
    //     if (box.size.height == listViewBox.size.height) return;
    //     if (box.size.height > 0 && box.size.width > 0) {
    //       hitListItem = true;
    //     }
    //   } else {
    //     return false;
    //   }
    // });

    // return !hitListItem;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) => _handleEmptySpaceTap(details, context),
      onLongPress: () => _handleEmptySpaceLongPress(context),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _buildRootNodes(),
        // children: [_buildNode(widget.root, 0)],
      ),
    );
  }

  List<Widget> _buildRootNodes() {
    if (widget.expansionMode == RootExpansionMode.hideAndExpand) {
      // 直接渲染根节点的子节点
      var list =
          widget.root.children.map((child) => _buildNode(child, 0)).toList();
      return list;
    }
    // 正常渲染根节点
    return [_buildNode(widget.root, 0)];
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
  // Widget _buildNode(FileNode node, [int depth = 0]) {
  //   final isExpanded = _expansionState[node.path] ?? false;
  //   final theme = Theme.of(context);
  //   final isDesktop =
  //       !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  //   return Padding(
  //     padding: EdgeInsets.only(left: depth * 24.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         GestureDetector(
  //           onDoubleTap: () => _handleDoubleTap(node),
  //           child: Container(
  //             padding: const EdgeInsets.symmetric(vertical: 8),
  //             decoration: BoxDecoration(
  //               color:
  //                   node.isExpanded
  //                       ? theme.colorScheme.primary.withOpacity(0.1)
  //                       : null,
  //               borderRadius: BorderRadius.circular(4),
  //             ),
  //             child: Row(
  //               children: [
  //                 Icon(
  //                   node.isDirectory
  //                       ? (isDesktop ? Icons.folder : Icons.folder) // 移除不存在的图标
  //                       : Icons.insert_drive_file,
  //                   color:
  //                       node.isDirectory
  //                           ? theme.colorScheme.primary
  //                           : theme.colorScheme.onSurface,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(
  //                   node.name,
  //                   style: theme.textTheme.bodyLarge?.copyWith(
  //                     fontWeight:
  //                         node.isDirectory
  //                             ? FontWeight.w500
  //                             : FontWeight.normal,
  //                   ),
  //                 ),
  //                 if (node.isDirectory) ...[
  //                   const SizedBox(width: 8),
  //                   Icon(
  //                     node.isExpanded
  //                         ? Icons.keyboard_arrow_down
  //                         : Icons.keyboard_arrow_right,
  //                     size: 18,
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           ),
  //         ),
  //         if (isExpanded && node.isDirectory)
  //           ...node.children.map((child) => _buildNode(child, depth + 1)),
  //       ],
  //     ),
  //   );
  // }
}
