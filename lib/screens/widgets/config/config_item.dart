import 'package:flutter/material.dart';
// 核心配置项数据模型
// @immutable
// abstract class ConfigItem {
//   final String title;
//   final IconData icon;
//   final Color? iconColor;
//   final String? subtitle;
//   final VoidCallback? onTap;

//   const ConfigItem({
//     required this.title,
//     required this.icon,
//     this.iconColor,
//     this.subtitle,
//     this.onTap,
//   });

//   // @override
//   // bool operator ==(Object other) => /* 实现相等逻辑 */;

//   // @override
//   // int get hashCode => /* 实现哈希码 */;
// }
abstract class ConfigItem extends ChangeNotifier {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;

  ConfigItem({
    required this.title,
    required this.icon,
    this.iconColor,
    this.subtitle,
  });

  void updateSwitchValue(bool newValue) {
    notifyListeners();
  }
}

class SwitchConfigItem extends ConfigItem {
  bool value;
  final ValueChanged<bool>? onChanged;

  SwitchConfigItem({
    required super.title,
    required super.icon,
    super.iconColor,
    super.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  void updateSwitchValue(bool newValue) {
    value = newValue;
    super.updateSwitchValue(newValue);
  }
}

class NavigationConfigItem extends ConfigItem {
  final VoidCallback onTap;

  NavigationConfigItem({
    required super.title,
    required super.icon,
    super.iconColor,
    super.subtitle,
    required this.onTap,
  });

  void navigateTo(BuildContext context, Widget widget) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (isIOS) {
            return _buildIOSSlideTransition(
              animation,
              secondaryAnimation,
              child,
            );
          } else {
            return _buildAndroidFadeTransition(animation, child);
          }
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildIOSSlideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.0),
          end: Offset.zero,
        ).animate(secondaryAnimation),
        child: child,
      ),
    );
  }

  Widget _buildAndroidFadeTransition(
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class InfoConfigItem extends ConfigItem {
  final String value;

  InfoConfigItem({
    required super.title,
    required super.icon,
    super.iconColor,
    super.subtitle,
    required this.value,
  });
}

class ThemeConfigItem extends ConfigItem {
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;
  ThemeConfigItem({
    required super.title,
    required super.icon,
    super.subtitle,
    required this.isDarkMode,
    this.onThemeChanged,
  });
}

class SectionHeaderItem extends ConfigItem {
  final Color? backgroundColor;
  SectionHeaderItem({required super.title, this.backgroundColor})
    : super(
        icon: Icons.label_outline, // 占位图标，实际不显示
        subtitle: null,
      );
}

class InputConfigItem extends ConfigItem {
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  InputConfigItem({
    required super.title,
    required super.icon,
    super.iconColor,
    super.subtitle,
    required this.value,
    required this.onChanged,
    this.validator,
    this.errorText,
  });
}

class LanguageConfigItem extends ConfigItem {
  final Locale currentLocale;
  final ValueChanged<Locale> onLanguageChanged;
  LanguageConfigItem({
    required super.title,
    required super.icon,
    super.iconColor,
    super.subtitle,
    required this.currentLocale,
    required this.onLanguageChanged,
  });
}

class ValidatedInputField extends StatefulWidget {
  final InputConfigItem item;
  const ValidatedInputField({super.key, required this.item});
  @override
  State<ValidatedInputField> createState() => _ValidatedInputFieldState();
}

class _ValidatedInputFieldState extends State<ValidatedInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _errorText;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.value);
    _focusNode = FocusNode(debugLabel: 'ValidatedInputField');
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      // 失去焦点时触发最终验证
      _validate(widget.item.value);
    }
  }

  void _validate(String value) {
    setState(() {
      _errorText = widget.item.validator?.call(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          errorText: _errorText ?? widget.item.errorText,
          border: InputBorder.none,
        ),
        onChanged: (value) {
          widget.item.onChanged(value);
          if (_focusNode.hasFocus) {
            _validate(value);
          }
          // if (widget.item.validator != null) {
          //   setState(() => _errorText = widget.item.validator!(value));
          // }
          // widget.item.onChanged(value);
        },
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();

    super.dispose();
  }
}
