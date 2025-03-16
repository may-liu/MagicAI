import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:magicai/modules/controls/adaptive_send_button.dart';
import 'package:magicai/screens/widgets/bubble/blog_post.dart';
import 'package:magicai/screens/widgets/bubble/chat_bubble.dart';
import 'package:magicai/services/abstract_client.dart';
import 'package:magicai/services/environment.dart';
import 'package:magicai/services/system_manager.dart';
import 'package:magicai/services/topic_manager.dart';
import 'package:magicai/entity/system_settings.dart';
import 'package:magicai/services/openai_client.dart';

class ChatScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;

  const ChatScreen({super.key, required this.currentThemeMode});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver
    implements TopicNotifyCallback {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isKeyboardVisible = false;
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;
  ButtonState _sendingButtonState = ButtonState.initial;

  final bool _isChatMode = false;

  final ValueNotifier<List<ChatMessage>> _messagesNotifier =
      ValueNotifier<List<ChatMessage>>([]);
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // final ValueNotifier<List<ChatMessage>> _messagestNotifier = ValueNotifier([]);
  final TextEditingController _textController = TextEditingController();
  late SystemConfig config;
  late StreamSubscription _subscription;
  late String _topicTitle = SystemManager.instance.currentTitle;
  final FocusNode _focusNode = FocusNode();

  // void _initTopics() {
  //   setState(() {
  //     _topicTitle = SystemManager.instance.currentTitle;
  //   });

  //   if (!TopicManager().containsTopic(_topicTitle)) {
  //     String filepath = SystemManager.instance.fullPathForTopic(_topicTitle);
  //     Topic t = Topic(_topicTitle, filepath);
  //     TopicManager().addTopic(_topicTitle, t);
  //     t.loadMessage();
  //   }
  //   Topic? t = TopicManager().getTopic(_topicTitle);

  //   setState(() {
  //     _messagestNotifier.value = t!.messages;
  //   });
  // }

  void _scrollListener() {
    // 获取当前滚动位置和最大滚动位置
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    // 判断是否接近底部
    _shouldAutoScroll = currentScroll >= maxScroll - 100;
  }

  void clearAndReload(List<ChatMessage> newList) {
    final oldList = _messagesNotifier.value;
    final oldIds = oldList.map((e) => e.startPos).toSet();
    final newIds = newList.map((e) => e.startPos).toSet();

    // 找出需要删除的项
    // final toRemoveIds = oldIds.difference(newIds);
    // final toRemoveIndices = <int>[];
    // for (var i = oldList.length - 1; i >= 0; i--) {
    //   if (toRemoveIds.contains(oldList[i].startPos)) {
    //     toRemoveIndices.add(i);
    //   }
    // }

    // 逐个移除需要删除的项并触发删除动画
    // for (var index in toRemoveIndices) {
    //   final removedMessage = oldList[index];
    //   setState(() {
    //     _messagesNotifier.value = [
    //       ..._messagesNotifier.value.sublist(0, index),
    //       ..._messagesNotifier.value.sublist(index + 1),
    //     ];
    //   });
    //   _listKey.currentState?.removeItem(
    //     index,
    //     (context, animation) => SizeTransition(
    //       sizeFactor: animation,
    //       child: _buildMessage(removedMessage, index),
    //     ),
    //   );
    // }

    // 找出需要添加的项
    // final toAddIds = newIds.difference(oldIds);
    // final toAddMessages =
    //     newList.where((e) => toAddIds.contains(e.startPos)).toList();

    // // 逐个添加需要添加的项并触发插入动画
    // for (var message in toAddMessages) {
    //   setState(() {
    //     _messagesNotifier.value.add(message);
    //   });
    //   _listKey.currentState?.insertItem(_messagesNotifier.value.length - 1);
    // }

    for (var element in oldList.reversed) {
      int pos = _messagesNotifier.value.length - 1;
      setState(() {
        _messagesNotifier.value = [
          ..._messagesNotifier.value.sublist(0, pos),
          ..._messagesNotifier.value.sublist(pos + 1),
        ];
      });
      _listKey.currentState?.removeItem(
        pos,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: _buildMessage(element, pos),
        ),
      );
    }

    // 逐个添加需要添加的项并触发插入动画
    for (var message in newList) {
      setState(() {
        _messagesNotifier.value.add(message);
      });
      _listKey.currentState?.insertItem(_messagesNotifier.value.length - 1);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _subscription = SystemManager.instance.registerEvent((event) {
      assert(event.newTopic != null);

      if (event.oldTopic != null) {
        event.oldTopic?.unRegEventNotifier(this);
      }

      clearAndReload(event.newTopic!.messages);

      event.newTopic?.regEventNotifier(this);

      return event.newTopic!;
    });

    SystemManager.instance.changeCurrentFile(
      SystemManager.instance.currentFile,
      force: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    SystemManager.instance.unRegisterEvent(_subscription);
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      _isKeyboardVisible = bottomInset > 0;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
    if (_isKeyboardVisible) {
      print('Keyboard is visible');
    } else {
      print('Keyboard is hidden');
    }
  }

  void _stopSending() {
    final mc = SystemManager.instance.currentModel();
    if (mc != null) {
      OpenaiClientManager.instance.getInstance(mc)?.abort();
      setState(() {
        _sendingButtonState = ButtonState.initial;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients &&
        _scrollController.offset < _scrollController.position.maxScrollExtent) {
      final double scrollDistance =
          _scrollController.position.maxScrollExtent - _scrollController.offset;
      if (scrollDistance > 0) {
        int durationMs = (scrollDistance * 0.3).toInt(); // 根据滚动距离动态计算时长
        durationMs = durationMs <= 0 ? 1 : durationMs;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeOut,
        );
      }
    }
  }

  // 修改_handleSubmitted方法
  void _handleSubmitted(String text) async {
    final mc = SystemManager.instance.currentModel();
    if (mc != null) {
      _textController.clear();

      setState(() {
        _sendingButtonState = ButtonState.sending;
      });

      Topic? tpk;

      if (!TopicManager().containsTopic(_topicTitle)) {
        String filepath = SystemManager.instance.fullPathForTopic(_topicTitle);
        tpk = Topic(_topicTitle, filepath);
        TopicManager().addTopic(_topicTitle, tpk);
      }

      tpk = TopicManager().getTopic(_topicTitle);

      // _messagesNotifier.value = tpk!.messages;

      var client = OpenaiClientManager.instance.getInstance(mc);

      tpk?.sendMessage(client!, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      body: Column(
        children: [Expanded(child: _buildChatContent()), _buildInput()],
      ),
      // ),
    );
  }

  Widget _buildChatContent() {
    // return AnimatedList(
    //   key: _listKey,
    //   initialItemCount: _messages.length,
    //   itemBuilder: (context, index, animation) {
    //     return SizeTransition(
    //       sizeFactor: animation,
    //       child: ListTile(
    //         key: ValueKey(_messages[index].startPos),
    //         trailing: Row(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             Flexible(child: _buildMessage(_messages[index], index)),
    //           ],
    //         ),
    //       ),
    //     );
    //   },
    // );

    return ValueListenableBuilder<List<ChatMessage>>(
      valueListenable: _messagesNotifier,
      builder: (context, value, child) {
        return AnimatedList(
          key: _listKey,
          initialItemCount: value.length,
          // shrinkWrap: true,
          // physics: const NeverScrollableScrollPhysics(),
          controller: _scrollController,
          padding: const EdgeInsets.all(8.0),
          reverse: false,
          itemBuilder:
              (context, index, animation) => SizeTransition(
                sizeFactor: animation,
                child: _buildMessage(value[index], index),
              ),
        );
      },
    );

    // return ValueListenableBuilder<List<ChatMessage>>(
    //   valueListenable: _messagesNotifier,
    //   builder: (context, value, child) {
    //     return ListView.builder(
    //       // shrinkWrap: true,
    //       // physics: const NeverScrollableScrollPhysics(),
    //       key: ValueKey('chat_item'),
    //       controller: _scrollController,
    //       padding: const EdgeInsets.all(8.0),
    //       reverse: false,
    //       itemCount: value.length,
    //       itemBuilder:
    //           (context, index) => TextInheritedWidget(
    //             key: ValueKey(index),
    //             text: value[index].content,
    //             child: _buildMessage(value[index], index),
    //           ),
    //     );
    //   },
    // );
  }

  Widget _buildMessage(ChatMessage message, index) {
    if (_isChatMode) {
      return ChatBubble(
        message: message,
        isUser: message.isUser,
        messageIndex: index,
      );
    } else {
      return BlogPost(
        key: ValueKey(
          '${SystemManager.instance.currentTitle}${message.startPos}+${index}',
        ),
        message: message,
        messageIndex: index,
      );
    }
  }

  void _submit() {
    _handleSubmitted(_textController.text);
  }

  Widget _buildInput() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: EnvironmentUtils.isDesktop ? 150 : 150,
              ),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(
                        LogicalKeyboardKey.enter,
                        control: true,
                      ):
                      _submit,
                  const SingleActivator(LogicalKeyboardKey.enter, meta: true):
                      _submit,
                },

                child: TextField(
                  controller: _textController,
                  // focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: EnvironmentUtils.isDesktop ? 12 : 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onSubmitted:
                      !EnvironmentUtils.isDesktop
                          ? null
                          : (_) => _handleSubmitted,
                  onEditingComplete:
                      EnvironmentUtils.isDesktop
                          ? () => _handleSubmitted(_textController.text)
                          : null,
                ),
              ),
            ),
          ),
          if (EnvironmentUtils.isDesktop)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: AdaptiveSendButton(
                onSend: () {
                  _handleSubmitted(_textController.text);
                },
                onStop: () {
                  _stopSending();
                },
                buttonState: _sendingButtonState,
              ),
            )
          else
            AdaptiveSendButton(
              onSend: () {
                _handleSubmitted(_textController.text);
              },
              onStop: () {
                _stopSending();
              },
              buttonState: _sendingButtonState,
            ),
        ],
      ),
    );
  }

  @override
  void onListItemChangedCallback(VoidCallback callback) {
    setState(() {
      callback();
    });
  }

  @override
  void onMessageTypeChanged(MessageType from, MessageType to) {
    // TODO: implement onMessageTypeChanged
  }

  @override
  void onRequestCallback(MessageType type, String message) {
    // TODO: implement onRequestCallback
  }

  @override
  void onRequestSendingCallback() {
    if (mounted) {
      setState(() {
        if (_sendingButtonState != ButtonState.sending) {
          _sendingButtonState = ButtonState.sending;
        }
      });
    }
  }

  @override
  void onRequestSentCallback() {
    if (mounted) {
      setState(() {
        if (_sendingButtonState != ButtonState.sent) {
          _sendingButtonState = ButtonState.sent;
        }
      });
    }
  }

  @override
  void onResponseDoneCallback() {
    if (mounted) {
      setState(() {
        if (_sendingButtonState != ButtonState.initial) {
          _sendingButtonState = ButtonState.initial;
        }
        // _messagestNotifier.value =
        //     TopicManager().getTopic(_topicTitle)!.messages;
      });
    }
  }

  @override
  void onResponseReceivingCallback(ChatMessage message) {
    // if (mounted) {
    //   setState(() {
    //     //   _messagestNotifier.value;
    //   });
    // }
  }

  @override
  void onMessageAddedCallback(ChatMessage message, int index) {
    addMessage(message);
  }

  @override
  void onMessageRemovedCallback(ChatMessage message, int index) {
    removeMessage(index);
  }

  @override
  void onMessageUpdatingCallback(ChatMessage message, int index) {
    updateMessage(message, index);
    if (_shouldAutoScroll) {
      _scrollToBottom();
    }
  }

  void addMessage(ChatMessage msg) {
    setState(() {
      _messagesNotifier.value = [..._messagesNotifier.value, msg];
    });
    _listKey.currentState?.insertItem(_messagesNotifier.value.length - 1);
  }

  void removeMessage(int index) {
    final removedMessage = _messagesNotifier.value[index];
    setState(() {
      _messagesNotifier.value = [
        ..._messagesNotifier.value.sublist(0, index),
        ..._messagesNotifier.value.sublist(index + 1),
      ];
    });
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _buildMessage(removedMessage, index),
      ),
    );
  }

  void updateMessage(ChatMessage msg, int index) {
    setState(() {
      _messagesNotifier.value = [
        ..._messagesNotifier.value.sublist(0, index),
        msg,
        ..._messagesNotifier.value.sublist(index + 1),
      ];
    });
  }
}

// class TextInheritedWidget extends InheritedWidget {
//   final String text;

//   const TextInheritedWidget({
//     super.key,
//     required this.text,
//     required super.child,
//   });

//   static TextInheritedWidget? of(BuildContext context) {
//     return context.dependOnInheritedWidgetOfExactType<TextInheritedWidget>();
//   }

//   @override
//   bool updateShouldNotify(TextInheritedWidget oldWidget) {
//     return oldWidget.text != text;
//   }
// }
