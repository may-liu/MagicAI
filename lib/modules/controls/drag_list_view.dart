import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:magicai/screens/ui_dialog.dart' as UIDialog;

abstract class DragableListItem {
  bool isHovering;
  bool isSelected;

  DragableListItem(this.isHovering, this.isSelected);

  bool get isAcceptable;

  String get path;

  String get name;

  bool rename(String newName);
  bool moveTo(DragableListItem item);
}

class FileNodeItem extends DragableListItem {
  FileNodeItem({
    bool isHovering = false,
    bool isSelected = false,
    required this.index,
  }) : super(isHovering, isSelected);

  final index;

  @override
  bool get isAcceptable => ((index == 3) || (index == 4)) ? true : false;

  @override
  bool moveTo(DragableListItem item) {
    print('moveTo');
    return true;
  }

  @override
  String get name => "Item $index";

  @override
  bool rename(String newName) {
    throw UnimplementedError();
  }

  @override
  String get path => throw UnimplementedError();
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Drag and Drop Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      // home: const FileDragAndDropPage(),
      home: MultiFileDragAndDropPage(
        items: [
          FileNodeItem(index: 1),
          FileNodeItem(index: 2),
          FileNodeItem(index: 3),
          FileNodeItem(index: 4),
          FileNodeItem(index: 5),
        ],
        reloadItemCallback: () {},
        doubleTapItemCallback: (item) {},
      ),
    );
  }
}

class FileDragAndDropPage extends StatefulWidget {
  const FileDragAndDropPage({super.key});

  @override
  State<StatefulWidget> createState() => _FileDragAndDropPageState();
}

class _FileDragAndDropPageState extends State<FileDragAndDropPage> {
  String? draggedFilePath;

  void _moveFile(String sourcePath, String destinationPath) {
    try {
      File sourceFile = File(sourcePath);
      sourceFile.renameSync(destinationPath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File moved successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error moving file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Drag and Drop')),
      body: Column(
        children: [
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                setState(() {
                  // 模拟目标文件夹路径
                  String destinationPath =
                      '/path/to/destination/folder/${path.basename(details.data)}';
                  _moveFile(details.data, destinationPath);
                  draggedFilePath = null;
                });
              },

              builder: (
                BuildContext context,
                List<dynamic> accepted,
                List<dynamic> rejected,
              ) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(child: Text('Drop files here')),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // 模拟 5 个文件
              itemBuilder: (BuildContext context, int index) {
                String filePath = '/path/to/source/file$index';
                return Draggable<String>(
                  data: filePath,
                  feedback: Container(
                    color: Colors.blue,
                    padding: const EdgeInsets.all(10),
                    child: const Text('Dragging file'),
                  ),
                  childWhenDragging: Container(),
                  child: ListTile(title: Text('File $index'), onTap: () {}),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

typedef DoubleTapItemCallback = void Function(DragableListItem item);

class MultiFileDragAndDropPage extends StatefulWidget {
  final List<DragableListItem> items;
  final bool mobileLayout;
  final VoidCallback reloadItemCallback;
  final DoubleTapItemCallback doubleTapItemCallback;
  const MultiFileDragAndDropPage({
    super.key,
    this.mobileLayout = false,
    required this.items,
    required this.reloadItemCallback,
    required this.doubleTapItemCallback,
  });

  @override
  State<StatefulWidget> createState() => _MultiFileDragAndDropPageState();
}

class _MultiFileDragAndDropPageState extends State<MultiFileDragAndDropPage> {
  late List<DragableListItem> _items;
  List<DragableListItem> selectedItems = [];
  
  bool isMultiSelectMode = false;
  bool isShiftPressed = false;
  final FocusNode _focusNode = FocusNode();
  int? editingIndex;
  late bool _mobileLayout;
  TextEditingController? _textEditingController;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
    _mobileLayout = widget.mobileLayout;
    // 请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textEditingController?.dispose();
    super.dispose();
  }

  void _moveItems(
    List<DragableListItem> sourceItems,
    DragableListItem destinationItem,
  ) {
    for (DragableListItem sourceItem in sourceItems) {
      // 这里可以添加实际的移动逻辑，例如文件移动等
      debugPrint('Moving $sourceItem to $destinationItem');
      sourceItem.moveTo(destinationItem);
    }
    widget.reloadItemCallback();
  }

  void _renameItem(int index, String newName) {
    setState(() {
      _items[index].rename(newName);
      widget.reloadItemCallback();
      editingIndex = null;
      _textEditingController?.dispose();
      _textEditingController = null;
    });
  }

  void _cancelRename() {
    setState(() {
      editingIndex = null;
      _textEditingController?.dispose();
      _textEditingController = null;
    });
  }

  void _addGroup() {
    UIDialog.showNewFolderDialog(context);
  }

  void _addItem() {
    debugPrint("添加");
    UIDialog.showNewFileDialog(context);
    // 可添加实际的添加逻辑，例如添加新的 item 到列表
    setState(() {
      // items.add('Item ${items.length + 1}');
    });
  }

  RelativeRect _calculatePosition(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset buttonPosition = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    return RelativeRect.fromLTRB(
      buttonPosition.dx - 50,
      buttonPosition.dy - 120, // 调整偏移量
      buttonPosition.dx + button.size.width,
      buttonPosition.dy + button.size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('File Drag and Drop')),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              setState(() {
                isShiftPressed = true;
              });
            }
          } else if (event is KeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              setState(() {
                isShiftPressed = false;
              });
            }
          }
        },
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (BuildContext context, int index) {
            DragableListItem item = _items[index];
            // bool isAcceptingDrop =
            //     (item == 'Item 3' || item == 'Item 4') &&
            //     selectedItems.isNotEmpty &&
            //     !selectedItems.contains(item);
            bool isAcceptingDrop =
                item.isAcceptable &&
                selectedItems.isNotEmpty &&
                !item.isSelected;

            if (editingIndex == index) {
              _textEditingController = TextEditingController(text: item.name);
              return ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        autofocus: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed:
                          () =>
                              _renameItem(index, _textEditingController!.text),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: _cancelRename,
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                if (isAcceptingDrop)
                  DragTarget<List<DragableListItem>>(
                    onAcceptWithDetails: (
                      DragTargetDetails<List<DragableListItem>> details,
                    ) {
                      _moveItems(details.data, item);
                    },
                    builder: (
                      BuildContext context,
                      List<dynamic> accepted,
                      List<dynamic> rejected,
                    ) {
                      return buildListItem(
                        context,
                        item,
                        isAcceptingDrop,
                        index,
                      );
                    },
                  )
                else
                  buildListItem(context, item, isAcceptingDrop, index),
                if (isMultiSelectMode)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Checkbox(
                      value: item.isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value!) {
                            selectedItems.add(item);
                            item.isSelected = true;
                          } else {
                            selectedItems.remove(item);
                            item.isSelected = false;
                          }
                        });
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Builder(
        builder: (selfcontext) {
          return FloatingActionButton(
            onPressed: () {
              showMenu(
                context: selfcontext,
                position: _calculatePosition(selfcontext),
                items: [
                  PopupMenuItem<String>(
                    value: 'AddFile',
                    onTap: _addItem,
                    child: const Text('新建聊天'),
                  ),
                  PopupMenuItem<String>(
                    value: 'AddGroup',
                    onTap: _addGroup,
                    child: const Text('新建组'),
                  ),
                ],
              );
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget buildListItem(
    BuildContext context,
    DragableListItem item,
    bool isAcceptingDrop,
    int index,
  ) {
    return LongPressDraggable<List<DragableListItem>>(
      data: selectedItems,
      feedback: Container(
        color: Colors.blue,
        padding: const EdgeInsets.all(10),
        child: Text('Dragging ${selectedItems.length} items'),
      ),
      childWhenDragging: Container(),
      child: GestureDetector(
        onTap: () {
          if (_mobileLayout) {
            widget.doubleTapItemCallback(item);
            widget.reloadItemCallback();
            return;
          } else {
            if (isMultiSelectMode || isShiftPressed) {
              setState(() {
                if (item.isSelected) {
                  selectedItems.remove(item);
                  item.isSelected = false;
                } else {
                  selectedItems.add(item);
                  item.isSelected = true;
                }
              });
            } else {
              bool selected = item.isSelected;
              setState(() {
                if (!item.isSelected) {
                  selectedItems = [item];
                } else {
                  selectedItems.clear();
                }
                for (DragableListItem item in _items) {
                  item.isSelected = false;
                }
                item.isSelected = !selected;
              });
            }
          }
        },
        onDoubleTap: () {
          widget.doubleTapItemCallback(item);
          widget.reloadItemCallback();

          // setState(() {
          //   selectedItems = [item];
          //   item.isSelected = true;
          // });
        },
        onSecondaryTapDown: (details) {
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              details.globalPosition.dx,
              details.globalPosition.dy,
            ),
            items: [
              if (isMultiSelectMode)
                PopupMenuItem<String>(
                  value: 'Cancel Multi Select',
                  child: const Text('取消多选'),
                )
              else
                PopupMenuItem<String>(
                  value: 'Multi Select',
                  child: const Text('多选'),
                ),
              PopupMenuItem<String>(value: 'Rename', child: const Text('重命名')),
            ],
          ).then((value) {
            if (value == 'Multi Select') {
              setState(() {
                isMultiSelectMode = true;
              });
            } else if (value == 'Cancel Multi Select') {
              setState(() {
                isMultiSelectMode = false;
                selectedItems.clear();
              });
            } else if (value == 'Rename') {
              setState(() {
                editingIndex = index;
              });
            }
          });
        },
        child: MouseRegion(
          onEnter: (event) {
            if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
              setState(() {
                item.isHovering = true;
              });
            }
          },
          onExit: (event) {
            if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
              setState(() {
                item.isHovering = false;
              });
            }
          },
          child: Stack(
            children: [
              ListTile(
                title: Text(item.name),
                tileColor:
                    // (!item.isSelected && item.isAcceptable)
                    isAcceptingDrop
                        ? (item.isSelected
                            ? Colors.lightBlue
                            : item.isHovering
                            ? Colors.green
                            : null)
                        : (item.isSelected ? Colors.lightBlue : null),
              ),
              if (!isMultiSelectMode && item.isHovering)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isMultiSelectMode = true;
                            selectedItems.add(item);
                            item.isSelected = true;
                          });
                        },
                        child: const Text('多选'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            editingIndex = index;
                          });
                        },
                        child: const Text('重命名'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
