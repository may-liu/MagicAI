import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:magicai/screens/widgets/adaptive_send_button.dart';
import 'package:magicai/screens/widgets/bubble/blog_post.dart';
import 'package:magicai/screens/widgets/bubble/chat_bubble.dart';
import 'package:magicai/services/abstract_client.dart';
import 'package:magicai/services/environment.dart';
import 'package:magicai/services/system_manager.dart';
import 'package:magicai/services/topic_manager.dart';
import 'package:magicai/entity/system_settings.dart';
import 'package:magicai/services/openai_client.dart';

class ChatScreen extends StatefulWidget {
  final Function(ThemeMode) updateThemeMode;
  final ThemeMode currentThemeMode;

  const ChatScreen({
    super.key,
    required this.updateThemeMode,
    required this.currentThemeMode,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver
    implements TopicNotifyCallback {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<AnimatedListState> listKey = GlobalKey();
  late ThemeMode _themeMode;

  bool _isKeyboardVisible = false;
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;
  ButtonState _sendingButtonState = ButtonState.initial;

  bool _isChatMode = false;

  final ValueNotifier<List<ChatMessage>> _messagestNotifier = ValueNotifier([]);
  final TextEditingController _textController = TextEditingController();
  late SystemConfig config;
  late StreamSubscription _subscription;
  late String _topicTitle = SystemManager.instance.currentTitle;
  final FocusNode _focusNode = FocusNode();

  void _initTopics() {
    setState(() {
      _topicTitle = SystemManager.instance.currentTitle;
    });

    if (!TopicManager().containsTopic(_topicTitle)) {
      String filepath = SystemManager.instance.fullPathForTopic(_topicTitle);
      Topic t = Topic(_topicTitle, filepath);
      TopicManager().addTopic(_topicTitle, t);
      t.loadMessage();
    }
    Topic? t = TopicManager().getTopic(_topicTitle);

    setState(() {
      _messagestNotifier.value = t!.messages;
    });
  }

  void _scrollListener() {
    // 获取当前滚动位置和最大滚动位置
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    // 判断是否接近底部
    _shouldAutoScroll = currentScroll >= maxScroll - 100;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _subscription = SystemManager.instance.registerEvent((event) {
      if (event.oldTopic != null) {
        event.oldTopic?.unRegEventNotifier(this);
      }
      assert(event.newTopic != null);
      event.newTopic?.regEventNotifier(this);
      setState(() {
        _messagestNotifier.value = event.newTopic!.messages;
      });
      return event.newTopic!;
    });

    SystemManager.instance.changeCurrentFile(
      SystemManager.instance.currentFile,
      force: true,
    );

    _themeMode = widget.currentThemeMode;

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
      final int durationMs = (scrollDistance * 0.3).toInt(); // 根据滚动距离动态计算时长
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOut,
      );
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

      _messagestNotifier.value = tpk!.messages;

      var client = OpenaiClientManager.instance.getInstance(mc);

      tpk.sendMessage(client!, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<ChatMessage>>(
              valueListenable: _messagestNotifier,
              builder: (context, value, child) {
                return ListView.builder(
                  // shrinkWrap: true,
                  // physics: const NeverScrollableScrollPhysics(),
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  reverse: false,
                  itemCount: value.length,
                  itemBuilder:
                      (context, index) => _buildMessage(value[index], index),
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
      // ),
    );
  }

  Widget _buildMessage(ChatMessage message, index) {
    if (_isChatMode) {
      return ChatBubble(
        message: message,
        isUser: message.isUser,
        messageIndex: index,
      );
    } else {
      return BlogPost(message: message, messageIndex: index);
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
        _messagestNotifier.value =
            TopicManager().getTopic(_topicTitle)!.messages;
      });
    }
  }

  @override
  void onResponseReceivingCallback(ChatMessage message) {
    if (mounted) {
      setState(() {
        _messagestNotifier.value;
      });
      if (_shouldAutoScroll) {
        _scrollToBottom();
      }
    }
  }
}
