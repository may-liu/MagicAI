import 'package:flutter/material.dart';

class LoadingOverlay {
  static final _instance = LoadingOverlay._internal();
  factory LoadingOverlay() => _instance;
  LoadingOverlay._internal();

  OverlayEntry? _overlayEntry;

  void show(BuildContext context) {
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class AsyncButton extends StatefulWidget {
  final Future Function() onPressed;
  final Widget child;

  const AsyncButton({super.key, required this.onPressed, required this.child});

  @override
  _AsyncButtonState createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePress,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, // 设置背景颜色为透明
        elevation: 0, // 去除阴影
        padding: EdgeInsets.zero, // 去除内边距
        // shape: const CircleBorder(), // 圆形边框
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // 设置圆角半径
        ),
      ),
      child:
          _isLoading
              ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : widget.child,
    );
  }

  Future<void> _handlePress() async {
    setState(() => _isLoading = true);
    LoadingOverlay().show(context); // 显示全局遮罩

    try {
      await widget.onPressed();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
      LoadingOverlay().hide(); // 隐藏遮罩
    }
  }
}
