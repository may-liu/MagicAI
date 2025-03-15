import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Send Button',
      theme: ThemeData.light(), // 使用系统亮色主题
      darkTheme: ThemeData.dark(), // 支持暗色主题
      home: const SendButtonDemo(),
    );
  }
}

enum ButtonState { initial, sending, sent }

class SendButtonDemo extends StatefulWidget {
  const SendButtonDemo({super.key});

  @override
  State<StatefulWidget> createState() => _SendButtonDemoState();
}

class _SendButtonDemoState extends State<SendButtonDemo> {
  late ButtonState _buttonState = ButtonState.initial;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Send Button Demo')),
      body: Center(
        child: AdaptiveSendButton(
          buttonState: _buttonState,
          onSend: () {
            setState(() {
              _buttonState = ButtonState.sending;
            });
          },
          onStop: () {
            setState(() {
              if (_buttonState == ButtonState.sent) {
                _buttonState = ButtonState.initial;
              }

              if (_buttonState == ButtonState.sending) {
                _buttonState = ButtonState.sent;
              }
            });
          },
        ),
      ),
    );
  }
}

typedef AdaptiveSendButtonSend = void Function();

typedef AdaptiveSendButtonStop = void Function();

class AdaptiveSendButton extends StatefulWidget {
  final AdaptiveSendButtonSend onSend;
  final AdaptiveSendButtonStop onStop;
  final ButtonState buttonState;
  const AdaptiveSendButton({
    super.key,
    required this.onSend,
    required this.onStop,
    required this.buttonState,
  });

  @override
  State<AdaptiveSendButton> createState() => _AdaptiveSendButtonState();
}

class _AdaptiveSendButtonState extends State<AdaptiveSendButton> {
  // ButtonState _buttonState = ButtonState.initial;

  bool _isWeb = false;

  @override
  void initState() {
    super.initState();
    // 平台判断只执行一次
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _detectPlatform();
    });
  }

  void _detectPlatform() {
    final platform = Theme.of(context).platform;
    setState(() {
      _isWeb =
          platform == TargetPlatform.windows ||
          platform == TargetPlatform.linux ||
          platform == TargetPlatform.macOS;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IconButton(
      iconSize: _isWeb ? 32 : 24, // Web平台加大点击区域
      padding: _isWeb ? const EdgeInsets.all(12) : null,
      style: IconButton.styleFrom(
        // 设置按钮的背景颜色
        backgroundColor: Colors.transparent,
        // 设置按钮的形状为矩形
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      onPressed: () {
        switch (widget.buttonState) {
          case ButtonState.initial:
            widget.onSend();
            break;
          case ButtonState.sending:
          case ButtonState.sent:
            widget.onStop();
            break;
        }
      },
      // _buttonState == ButtonState.sending ? null : _simulateNetworkRequest,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildStateIcon(theme, colorScheme),
      ),
    );
  }

  Widget _buildStateIcon(ThemeData theme, ColorScheme colorScheme) {
    switch (widget.buttonState) {
      case ButtonState.initial:
        return Icon(
          Icons.send,
          key: const ValueKey('send'),
          color: theme.iconTheme.color,
        );
      case ButtonState.sending:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.secondary,
          ),
        );
      case ButtonState.sent:
        return Icon(
          Icons.stop,
          key: const ValueKey('sent'),
          color: colorScheme.primary,
        );
    }
  }
}
