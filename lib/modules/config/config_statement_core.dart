import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'config_item.dart';

class SettingsStateList extends StatefulWidget {
  final List<ConfigItem> items;
  final double iconSize;
  final Color? dividerColor;

  @override
  State<SettingsStateList> createState() => _SettingsStateListState();

  const SettingsStateList({
    super.key,
    required this.items,
    this.iconSize = 28.0,
    this.dividerColor,
  });
}

class _SettingsStateListState extends State<SettingsStateList> {
  late List<ConfigItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items; // 初始化列表
    // 订阅所有配置项的通知（简化示例，实际需要遍历添加监听）
    // for (var item in _items) {
    //   if (item is ChangeNotifier) {
    //     item.addListener(_refresh);
    //   }
    // }
  }

  void _refresh() {
    setState(() {}); // 强制刷新
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      itemCount: widget.items.length,
      separatorBuilder:
          (_, __) => Divider(
            height: 1,
            color: widget.dividerColor ?? theme.dividerColor.withOpacity(0.1),
            indent: 72,
          ),
      itemBuilder:
          (context, index) => _buildItem(widget.items[index], theme, isIOS),
    );
  }

  Widget _buildItem(ConfigItem item, ThemeData theme, bool isIOS) {
    if (item is SectionHeaderItem) {
      return Container(
        color: item.backgroundColor ?? theme.dividerColor.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          item.title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    final iconColor = item.iconColor ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListTile(
        leading: _buildLeading(iconColor, item.icon),
        title: Text(item.title, style: theme.textTheme.titleMedium),
        subtitle:
            item.subtitle != null
                ? Text(item.subtitle!, style: theme.textTheme.bodySmall)
                : null,
        trailing: _buildTrailing(item, theme, isIOS),
        onTap:
            () =>
                item is NavigationConfigItem
                    ? item.navigateTo(context, item.childWidget)
                    : null,
      ),
    );
  }

  Widget _buildLeading(Color color, IconData icon) => Hero(
    tag: icon.codePoint,
    child: Container(
      width: widget.iconSize + 8,
      height: widget.iconSize + 8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: widget.iconSize, color: color),
    ),
  );

  Widget? _buildTrailing(ConfigItem item, ThemeData theme, bool isIOS) {
    if (item is SwitchConfigItem) {
      return Switch.adaptive(
        value: item.value,
        // onChanged: item.onChanged,
        onChanged: (value) => item.updateSwitchValue(value),
        activeColor: isIOS ? theme.colorScheme.primary : null,
      );
    }
    if (item is InputConfigItem) {
      return SizedBox(width: 150, child: ValidatedInputField(item: item));
    }
    if (item is ThemeConfigItem) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Switch.adaptive(
          key: ValueKey(item.isDarkMode),
          value: item.isDarkMode,
          onChanged: (value) => item.updateSwitchValue(value),
          activeColor: isIOS ? theme.colorScheme.primary : null,
        ),
      );
    }
    if (item is NavigationConfigItem) {
      return Icon(
        isIOS ? CupertinoIcons.chevron_forward : Icons.arrow_forward,
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
      );
    }
    if (item is InfoConfigItem) {
      return Text(item.value, style: theme.textTheme.bodyMedium);
    }
    return null;
  }
}
