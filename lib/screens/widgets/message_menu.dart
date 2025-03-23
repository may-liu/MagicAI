import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:magicai/services/abstract_client.dart';
import 'package:magicai/services/system_manager.dart';
import 'package:magicai/services/topic_manager.dart';

enum PopupMenuItemType { copy, regenerate, delete }

typedef PopupMenuItemFunction =
    void Function(PopupMenuItemType type, ChatMessage message);

class _MessageMenuController {
  void show({
    required BuildContext context,
    required Offset globalPosition,
    required List<PopupMenuItem> items,
  }) {
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          globalPosition,
          globalPosition.translate(1, 1), // 创建微小矩形确保点击位置正确
        ),
        Offset.zero & overlay.size,
      ),
      items: items,
    );
  }
}

class MessageMenu extends StatefulWidget {
  final Widget child;
  final ChatMessage message;
  final bool isUser;
  final int index;

  const MessageMenu({
    super.key,
    required this.child,
    required this.message,
    required this.isUser,
    required this.index,
  });

  @override
  State<MessageMenu> createState() => _MessageMenuState();
}

class _MessageMenuState extends State<MessageMenu> {
  final _menuController = _MessageMenuController();
  bool _hovering = false;

  void _showContextMenu(TapDownDetails details) {
    _menuController.show(
      context: context,
      globalPosition: details.globalPosition,
      items: [
        PopupMenuItem(
          onTap: _copyMessage,
          child: const ListTile(
            leading: Icon(Icons.content_copy),
            title: Text('复制'),
          ),
        ),
        if (!widget.isUser)
          PopupMenuItem(
            onTap: _regenerate,
            child: const ListTile(
              leading: Icon(Icons.refresh),
              title: Text('重新生成'),
            ),
          ),
        PopupMenuItem(
          onTap: _branch,
          child: const ListTile(
            leading: Icon(Icons.turn_sharp_left_rounded),
            title: Text('分支'),
          ),
        ),
        PopupMenuItem(
          onTap: _delete,
          child: const ListTile(
            leading: Icon(Icons.delete),
            title: Text('删除'),
            textColor: Colors.red,
          ),
        ),
      ],
    );
  }

  // 操作方法
  void _copyMessage() =>
      Clipboard.setData(ClipboardData(text: widget.message.content));
  void _regenerate() => SystemManager.instance.regenerate(widget.index);
  void _branch() {
    SystemManager.instance
        .branchMessage(widget.index)
        .then(
          (value) =>
              SystemManager.instance.changeCurrentFile(value, force: true),
        );
  }

  void _delete() {
    TopicManager().currentTopic?.deleteMessage(widget.index);
    debugPrint(
      'debug for Delete message: on delete menu: index is ${widget.index} & content is ${widget.message.content}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onSecondaryTapDown: _showContextMenu,
        onLongPressStart:
            (details) => _showContextMenu(
              TapDownDetails(globalPosition: details.globalPosition),
            ),
        // onLongPress:
        // () => _showContextMenu(TapDownDetails(globalPosition: Offset.zero)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.child,
            // SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // 宽度占满父组件
              height: 35, // 设置一个固定高度
              // color: Colors.red,
              child: Stack(
                children: [
                  if (_hovering)
                    Positioned(
                      right: 0, //widget.isUser ? 0 : null,
                      left: null, //widget.isUser ? null : 0,
                      top: 0,
                      child: _buildFloatingMenu(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // IconButton(
  //   icon: Icon(_expanded ? Icons.arrow_drop_down : Icons.arrow_right),
  //   onPressed: () => setState(() => _expanded = !_expanded),
  //   iconSize: 18,
  //   padding: EdgeInsets.zero,
  //   constraints: BoxConstraints(),
  Widget _buildFloatingMenu() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.content_copy, size: 18),
              // padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed: _copyMessage,
            ),
            if (!widget.isUser)
              IconButton(
                icon: const Icon(Icons.turn_sharp_left_rounded, size: 18),
                constraints: BoxConstraints(),
                onPressed: _branch,
              ),
            // if (!widget.isUser)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              // padding: EdgeInsets.zero,
              constraints: BoxConstraints(),

              onPressed: _regenerate,
            ),

            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              // padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed: _delete,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
